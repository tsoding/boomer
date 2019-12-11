with import <nixpkgs> {}; let
  nim_1_0 = callPackage ./overlay/nim_1_0.nix {};
in rec {
  boomerEnv = stdenv.mkDerivation {
    name = "boomer-env";
    buildInputs = [ stdenv
                    gcc
                    gdb
                    pkgconfig
                    nim_1_0
                    xorg.libX11
                    xorg.libXrandr
                    xorg.libXext
                    libGL
                    libGLU
                    freeglut
                  ];
    LD_LIBRARY_PATH="/run/opengl-driver/lib;${xorg.libX11}/lib/;${libGL}/lib/;${libGLU}/lib;${freeglut}/lib;${xorg.libXrandr}/lib;${xorg.libXext}/lib";
  };
}
