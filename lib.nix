{
  self,
  pkgs,
  lib,
  ...
}:
let
  petcatSupportedCbmFileTypes = [
    "prg"
    "seq"
  ];
  removeExtension = filename: builtins.match "(.+)\\.[^.]+" filename;
  decToHex =
    dec: hex:
    if dec == 0 then
      hex
    else
      decToHex (dec / 16) (
        hex + builtins.elemAt (lib.stringToCharacters "0123456789ABCDEF") (lib.mod dec 16)
      );
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
      name,
      src,
      targetSystem,
      clangFlags ? [ ],
      ...
    }@args:
    pkgs.stdenv.mkDerivation {
      inherit name src;
      buildPhase = ''
        runHook preBuild
        ${pkgs.llvm-mos-sdk}/bin/mos-${targetSystem}-clang ${lib.concatStringsSep " " clangFlags}
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
    - acmeFlags (List of String): additional compiler flags.
    - debug (Bool): Should the derivation include debugging artifacts like labels?

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
      name,
      src,
      acmeFlags ? [ ],
      debug ? false,
      ...
    }@args:
    pkgs.stdenv.mkDerivation {
      inherit name src;
      buildPhase = ''
        runHook preBuild
        ${pkgs.acme}/bin/acme ${lib.concatStringsSep " " acmeFlags}
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
            cp ${name}.prg $out
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
    - debug (Bool): Should the output derivation include build and debugging artifacts?

    # Example:
    ```nix
      packages.default = buildBasicPrg {
        name = "c64tool"
        version = "0.0.1"
        src = ./.;
      };
    ```
  */
  buildBasicPrgs =
    {
      name,
      src,
      targetSystem,
      debug ? false,
      ...
    }@args:
    pkgs.stdenv.mkDerivation {
      inherit name src;
      buildPhase = ''
        runHook preBuild
        find . -name "*.bas" -execdir sh -c '${pkgs.vice}/bin/petcat -w2 -o $1.prg -- $1' sh {} \;
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
            cp *.bas.prg $out
          '';
    }
    // removeAttrs args [
      "targetSystem"
      "debug"
    ];

  /**
    Build a cbm compatible prg files from a modern binary files

    # Type:
    `buildBinaryPrgs = { targetSystem, ... } @ args: Derivation`

    # Args:
    - name (String): The name of the derivation.
    - src (Path): The path to the source files for the derivation.
    - includedFiles (List of String): The file extensions to include.
    - debug (Bool): Should the output derivation include build and debugging artifacts?
  */
  buildBinaryPrgs =
    {
      name,
      src,
      includedFiles ? [ "*.prg" ],
      debug ? false,
      ...
    }@args:
    let
      loadAddressHex =
        if builtins.isString args.loadAddress then args.loadAddress else decToHex args.loadAddress;
    in
    pkgs.stdenv.mkDerivation {
      inherit name src;
      buildPhase = ''
        runHook preBuild
        ${lib.optionalString (builtins.hasAttr "loadAddress") (
          builtins.concatStringsSep "\n" (
            map (
              fileType:
              ''find -name ${fileType} --execdir sh -c 'echo "${loadAddressHex}" | xxd -r -p | cat - $1 > $1' sh {}''
            ) includedFiles
          )
        )}
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
    };

  /**
    Build a PETSCII text file asset using petcats

    # Type:
      `buildPetsciiTextFile = { ... } @ args: Derivation`

    # Args:
    - name (String): The name of the resulting derivation.
    - src (Path): The path to the source files for the derivation.
    - cbmFileType (String): The cbm file type for the output text.
    - petcatFlags (List of String): A list of flags passed directly to petcat.
    - debug (Bool): Should the output derivation include build and debugging artifacts?

    # Example:
     ```nix
      packages.default = buildPetsciiTextFile {
       name = "c64doc"
       version = "0.0.1"
       src = ./.
      }
     ```
  */
  buildPetsciiTextFiles =
    {
      name,
      src,
      cbmFileType ? "prg",
      petcatFlags ? [ ],
      debug ? false,
      ...
    }@args:
    assert (lib.assertOneOf "cbmFileType" cbmFileType petcatSupportedCbmFileTypes);
    pkgs.stdenv.mkDerivation {
      inherit name src;
      buildPhase = ''
        runHook preBuild
        find . -name "*.txt" -execdir sh -c '${pkgs.vice}/bin/petcat ${lib.concatStringsSep " " petcatFlags} -text -w2 -o $1.${cbmFileType} -- $1' sh {} \;
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
    - debug (Bool): Should debug label output files be included in the derivation

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
      buildPhase = ''
        runHook preBuild
        ${pkgs.vice}/bin/c1541 -format ${name},0 d64 ${name}.d64
        ${lib.optionalString (builtins.hasAttr "starfile" args) '''find . -name ${args.starfile} -execdir sh -c '${pkgs.vice}/bin/c1541 -attach "${name}.d64" -write "$1" "${removeExtension (baseNameOf args.starfile)}"' sh {} \;''}
        find . -name "*.bas.prg" -execdir sh -c '${pkgs.vice}/bin/c1541 -attach "${name}.d64" -write "$1" "$(basename "$1" .bas.prg)"' sh {} \;
        find . -name "*.prg" \! -name "*.bas.prg" -execdir sh -c '${pkgs.vice}/bin/c1541 -attach "${name}.d64" -write "$1" "$(basename "$1" .prg)"' sh {} \;
        find . -name "*.seq" -execdir sh -c '${pkgs.vice}/bin/c1541 -attach ${name}.d64 -write "$1" "$(basename "$1" .seq)"' sh {} \;
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
            cp ${name}.d64 $out
          '';
    }
    // removeAttrs args [
      "extraIncludes"
      "debug"
      "starfile"
    ];

  /**
      Test a cbm program using the vice Emulator

      # Type:
      checkWithVice = { name, emulator, configFile, monitorCommandsFile, keystrokesFile, diskFile, exitOn, exitAfter, warp, extraViceFlags, nativeCheckPhase, ...}@args : Derivation

     Args:
     - name (String): The name of the test being run.
     - emulator (String): The basename of the emulator executable to use.
     - configFile (Path): A path to the vice config to be used for the test.
     - monitorCommandsFile (Path): A path to a monitor commands script to be used for the test.
     - keystrokesFile (Path): A path to a text file containing a series of keystrokes to be loaded into the keyboard input buffer upon program load.
     - fileUnderTest (Path): A path to the program file or disk image containing the program file under test.
     - failAfter (Int): A timelimit in seconds of realtime.
     - warp (Bool): Use vice warp mode to speed up test?
     - extraViceFlags (List of String): Extra flags to be passed to the emulator executable.
     - nativeCheckPhase (String): A script containing shell commands to be run on the emulator host system after the emulator run succeeds.

    Example:
      checks.default = checkWithVice {
        name = "myViceTest";
        emulator = "x128";
        fileUnderTest = ./prgdisk.d64;
        configFile = ./myViceTestConfig.ini;
        monitorCommandsFile = ./myViceTestMonitorCommands.ini;
        keystrokesFile = ./myViceTestKeystrokes.txt;
      }
  */
  checkWithVice =
    {
      name,
      emulator ? "x64sc",
      fileUnderTest,
      configFile,
      monitorCommandsFile,
      keystrokesFile,
      failAfter ? 300,
      warp ? true,
      extraViceFlags ? [ ],
      nativeCheckPhase ? "",
      ...
    }:
    let
      viceFlags = [
        ''-initbreak ready''
        ''-config ${configFile}''
        ''-keybuf "${builtins.readFile keystrokesFile}"''
      ]
      ++ lib.optional warp [
        ''-warp''
      ]
      ++ [
        ''-moncommands ${monitorCommandsFile}''
        ''-autostart ${fileUnderTest}''
      ]
      ++ extraViceFlags;
    in
    pkgs.runCommand name { } ''
      export HOME=$(mktemp -d)
      timeout ${failAfter} ${self.packages.vice-headless}/bin/${emulator} ${lib.concatStringsSep " " viceFlags}
      if [[ $ == 124 || $ == 125 || $ == 126 || $ == 127 || $ == 137 ]]; then
        echo "failAfter timeout time of $failAfter seconds has been exceeded. $name failed.
        exit $
      fi
      ${nativeCheckPhase}
      mkdir -p $out
      touch $out/passed
    '';
}
