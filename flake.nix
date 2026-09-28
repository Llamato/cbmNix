{
  description = "A collection of utility functions for packaging commodore business machines software software";
  outputs = {...}:
    let
    in
      {
        lib = {
          mk = { pkgs }: let 
            lib = pkgs.lib;
            makeFlagsString = flags: pkgs.lib.concatStringsSep " " flags;
          in {
            buildClangPrg = 
              args@{ ... }: 
              pkgs.stdenv.mkDerivation (
                args // {
                  buildPhase = ''
                    runHook preBuild
                    ${pkgs.llvm-mos-sdk}/bin/mos-${args.targetSystem}-clang ${makeFlagsString (args.clangFlags or [ ])}
                    runHook postBuild
                  '';
                  installPhase = ''
                    mkdir -p $out
                    cp *.prg $out
                  '';
                }
              );
            buildAcmePrg =
              args@{ ... }: 
              pkgs.stdenv.mkDerivation (
                args
                // {
                  buildPhase = ''
                    runHook preBuild
                    ${pkgs.acme}/bin/acme ${makeFlagsString (args.acmeFlags or [ ])}
                    runHook postBuild
                  '';
                  installPhase = ''
                    mkdir -p $out
                    cp ${args.name}.* $out
                  '';
                }
              );
            buildBasicPrg =
              args@{ ... }:
              pkgs.stdenv.mkDerivation (
                args
                // {
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
              );
            buildTextAsset = 
              args@{ ... }:
              pkgs.stdenv.mkDerivation (
                args // {
                  buildPhase = ''
                    runHook preBuild
                    find . -name "*.txt" -execdir sh -c '${pkgs.vice}/bin/petcat -text -w2 -o $1.prg -- $1' sh {} \;
                    runHook postBuild
                  '';
                  installPhase = ''
                    mkdir -p $out
                    cp *.txt.prg $out
                  '';
                }
              );
            buildBinaryAsset =
              args@{ ... }:
              pkgs.stdenv.mkDerivation (
                args
                // {
                  buildPhase = ''
                    runHook preBuild
                    mkdir -p $out
                    cp *.bin $out
                    runHook postBuild
                  '';
                }
              );
            buildD64 = { name, paths, ... }:
              pkgs.stdenv.mkDerivation {
                inherit name;
                src = pkgs.symlinkJoin {
                  inherit name;
                  inherit paths;
                };
                buildPhase = ''
                  runHook preBuild
                  ${pkgs.vice}/bin/c1541 -format ${name},0 d64 ${name}.d64
                  find . -name "*.prg" -a \! \( -name "*.bas.*" \) -execdir sh -c '${pkgs.vice}/bin/c1541 -attach "${name}.d64" -write "$1" "$(basename "$1" .prg)"' sh {} \;
                  find . -name "*.bas.prg" -execdir sh -c '${pkgs.vice}/bin/c1541 -attach "${name}.d64" -write "$1" "$(basename "$1" .bas.prg)"' sh {} \;
                  find . -name "*.seq" -execdir sh -c '${pkgs.vice}/bin/c1541 -attach ${name}.d64 -write "$1" "$(basename "$1" .seq)"' sh {} \;
                  find . -name "*.bin" -execdir sh -c '${pkgs.vice}/bin/c1541 -attach ${name}.d64 -write "$1" "$(basename "$1" .bin)"' sh {} \;
                  runHook postBuild
                '';
                installPhase = ''
                  mkdir -p $out
                  cp ${name}.d64 $out
                  cp ${name}.vicelabel
                '';
              };
          };
        };
      };
}
