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
          boomer = let
            opengl = pkgs.nimPackages.buildNimPackage rec {
              pname = "opengl";
              version = "1.2.8";
              src = pkgs.fetchFromGitHub {
                owner = "nim-lang";
                repo = "opengl";
                rev = version;
                hash = "sha256-OHdoPJsmCFdyKV7FGd/r+6nh6NRF7TPhuAx7o/VpiDg=";
              };
            };
          in
            pkgs.nimPackages.buildNimPackage {
              pname = "boomer";
              version = "0.0.1";
              nimBinOnly = true;

              src = ./.;

              buildInputs = with pkgs.nimPackages; [
                x11
                opengl
              ];
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
