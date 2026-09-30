{ pkgs }:
let
  petcatSupportedCbmFileTypes = [
    "prg"
    "seq"
  ];
  lib = pkgs.lib;
  makeFlagsString = flags: lib.concatStringsSep " " flags;
  removeExtension = filename: builtins.match "(.+)\\.[^.]+" filename;
in
{

  /**
    Build a c program for 6500 series of processors using llvm-mos

    # Type:
    `buildClangPrg = { targetSystem, clangFlags, ... } @ args: Derivation`

    # Args:
    - `name` (String): The name of the resulting derivation.
    - `src` (Path): The path to the source files for the derivation.
    - `targetSystem` (String): The shorthand name for the the computer model the program shall run on.
    - `clangFlags` (List of String): additional compiler flags.

    # Example:
    ```nix
      packages.default = buildClangPrg {
        name = "Firefighter";
        version = "1.0.0";
        src = ./.;
      };
    ```
  */
  buildClangPrg =
    {
      targetSystem,
      clangFlags ? [ ],
      ...
    }@args:
    pkgs.stdenv.mkDerivation {
      buildPhase = ''
        runHook preBuild
        ${pkgs.llvm-mos-sdk}/bin/mos-${targetSystem}-clang ${makeFlagsString clangFlags}
        runHook postBuild
      '';
      installPhase = ''
        mkdir -p $out
        cp *.prg $out
      '';
    }
    // removeAttrs args [
      "targetSystem"
      "clangFlags"
    ];

  /**
    Build an assembly program for the 6500 series of processors using the ACME cross assembler

    # Type:
    `buildAcmePrg = { debug, ...} @ args: Derivation`

    # Args:
    - name (String): The name of the resulting derivation.
    - src (Path): The path to the source files for the derivation.
    - debug (Bool): Should the derivation include debugging artifacts like labels?
    - acmeFlags (List of String): additional compiler flags.

    # Example:
     ```nix
        packages.default = buildAcmePrg {
          name = "c64demo";
          version = "0.0.1";
          src = ./.;
        };
      ```
  */
  buildAcmePrg =
    {
      debug ? false,
      acmeFlags ? [ ],
      ...
    }@args:
    pkgs.stdenv.mkDerivation {
      buildPhase = ''
        runHook preBuild
        ${pkgs.acme}/bin/acme ${makeFlagsString acmeFlags}
        runHook postBuild
      '';
      installPhase =
        if debug then
          ''
            mkdir -p $out
            cp * $out
          ''
        else
          ''
            mkdir -p $out
            cp *.prg $out
          '';
    }
    // removeAttrs args [
      "debug"
      "acmeFlags"
    ];

  /**
    Build a basic program for the 6500 series of processors using the petcat's basic tokenizer

    # Type:
     `buildBasicPrg = { targetSystem, ... } @ args: Derivation`

    # Args:
    - name (String): The name of the resulting derivation.
    - src (Path): The path to the source files for the derivation.
    - targetSystem (String): The shorthand name for the the computer model the program shall run on.

    # Example:
    ```nix
      packages.default = buildBasicPrg {
        name = "c64tool"
        version = "0.0.1"
        src = ./.;
      };
    ```
  */
  buildBasicPrg =
    { targetSystem, ... }@args:
    pkgs.stdenv.mkDerivation {
      buildPhase = ''
        runHook preBuild
        find . -name "*.bas" -execdir sh -c '${pkgs.vice}/bin/petcat -w2 -o $1.prg -- $1' sh {} \;
        runHook postBuild
      '';
      installPhase = ''
        mkdir -p $out
        cp *.bas.prg $out
      '';
    }
    // removeAttrs args [ "targetSystem" ];

  /**
    Build a PETSCII text file asset using petcats

    # Type:
      `buildPetsciiAsset = { ... } @ args: Derivation`

    # Example:
     ```nix
      packages.default = buildPetsciiTextFile {
       name = "c64doc"
       version = "0.0.1"
       src = ./.
      }
     ```
  */
  buildPetsciiTextFile =
    {
      cbmFileType ? "prg",
      petcatFlags,
      ...
    }@args:
    assert (lib.assertOneOf "cbmFileType" cbmFileType petcatSupportedCbmFileTypes);
    pkgs.stdenv.mkDerivation {
      buildPhase = ''
        runHook preBuild
        find . -name "*.txt" -execdir sh -c '${pkgs.vice}/bin/petcat ${makeFlagsString petcatFlags} -text -w2 -o $1.${cbmFileType} -- $1' sh {} \;
        runHook postBuild
      '';
      installPhase = ''
        mkdir -p $out
        cp *.txt.prg $out
      '';
    }
    // removeAttrs args [
      "cbmFileType"
      "petcatFlags"
    ];

  /**
    Build a d64 disk image from a list of paths

    # Type:
     `buildPetsciiAsset = { name, paths, extraIncludes, ... } @ args: Derivation`

    # Args:
    - name (String): The name of the resulting derivation.
    - paths (List of path): Paths of files to be included in the derivation
    # Example:
     ```nix
     packages.default = buildD64 {
       name = "Spacebirds64"
       version = "1.0.0";
       src = ./.;
     }
     ```
  */
  buildD64 =
    {
      name,
      paths,
      debug ? false,
      ...
    }@args:
    pkgs.stdenv.mkDerivation {
      inherit name;
      src = pkgs.symlinkJoin {
        inherit name;
        inherit paths;
      };
      buildPhase =
        lib.concatStringsSep "\n" [
          "runHook preBuild"
        ]
        ++ [
          "runHook postBuild"
          "${pkgs.vice}/bin/c1541 -format ${name},0 d64 ${name}.d64"
        ]
        ++ lib.optional (builtins.hasAttr "starfile" args) [
          ''find . -name ${args.starfile} -execdir sh -c '${pkgs.vice}/bin/c1541 -attach "${name}.d64" -write "$1" "${removeExtension (baseNameOf args.starfile)}"' sh {} \;''
        ]
        ++ [
          ''find . -name "*.bas.prg" -execdir sh -c '${pkgs.vice}/bin/c1541 -attach "${name}.d64" -write "$1" "$(basename "$1" .bas.prg)"' sh {} \;''
          ''find . -name "*.prg" \! -name "*.bas.prg" -execdir sh -c '${pkgs.vice}/bin/c1541 -attach "${name}.d64" -write "$1" "$(basename "$1" .prg)"' sh {} \;''
          ''find . -name "*.seq" -execdir sh -c '${pkgs.vice}/bin/c1541 -attach ${name}.d64 -write "$1" "$(basename "$1" .seq)"' sh {} \;''
        ]
        ++ [
          "runHook postBuild"
        ];

      installPhase =
        if debug then
          ''
            mkdir -p $out
            cp * $out
          ''
        else
          ''
            mkdir -p $out
            cp *.prg $out
          '';
    }
    // removeAttrs args [
      "extraIncludes"
      "debug"
      "starfile"
    ];
}
