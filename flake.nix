{
  description = "A collection of utility functions for packaging commodore business machines software software";
  inputs = {
    nixpkgs = {
      url = "github:NixOs/nixpkgs/nixpkgs-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };
  outputs =
    { nixpkgs, ... }:
    let
      libfile = ./lib.nix;
      darwinSystem = [
        "aarch64-darwin"
      ];
      linuxSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "riscv64-linux"
      ];
      allSystems = linuxSystems ++ darwinSystem;
      lib = nixpkgs.lib;
      forAllSystems = lib.genAttrs allSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      lib = {
        mk =
          { pkgs }:
          import libfile {
            inherit pkgs;
            lib = pkgs.lib;
          };
      };
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          docs =
            pkgs.runCommand "cbmNix-docs"
              {
                buildInputs = with pkgs; [
                  nixdoc
                ];
              }
              ''
                mkdir -p $out
                nixdoc --file ${libfile} \
                --category cbm \
                --description "A collection of utility functions for packaging commodore business machines software software" \
                --prefix cbmNix \
                > $out/index.md
              '';
        in
        {
          inherit docs;
          default = docs;
        }
      );
      
      checks = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          formatter = pkgs.runCommand "formatter" {
            src = ./.; #Not being fetched
          } ''
            find . -name '*.nix' -exec ${pkgs.nixfmt}/bin/nixfmt --check {} +
            mkdir -p $out
            touch $out/pass
          '';
          in
          {
            inherit formatter;
            default = formatter;
          }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              nixfmt
              nixd
              nixdoc
            ];
          };
        }
      );
    };
}
