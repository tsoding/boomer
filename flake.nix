{
  description = "Zoomer application for Linux";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        formatter = pkgs.alejandra;
        packages = rec {
          boomer = pkgs.buildNimPackage {
            pname = "boomer";
            version = "0.0.1";

            src = ./.;

            lockFile = ./lock.json;

            propagatedBuildInputs = with pkgs; [
              xorg.libX11
              xorg.libXrandr
              xorg.libXext
              libGL
              libGLU
            ];

            meta = with nixpkgs.lib; {
              mainProgram = "boomer";
              description = "Zoomer application for Linux";
              homepage = "https://github.com/tsoding/boomer";
              license = licenses.mit;
            };
          };
          default = boomer;
        };
        apps = rec {
          boomer = flake-utils.lib.mkApp {drv = self.packages.${system}.boomer;};
          default = boomer;
        };
      }
    );
}
