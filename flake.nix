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
      packages =
        let
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
        in
        forAllSystems (
          system:
          let
            pkgs = import nixpkgs { inherit system; };
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
    };
}
