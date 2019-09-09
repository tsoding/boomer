with import <nixpkgs> {}; {
    boomerEnv = stdenv.mkDerivation {
        name = "boomer-env";
        buildInputs = [ stdenv
                        gcc
                        pkgconfig
                        nim
                        xorg.libX11
                        libGL
                        libGLU
                        freeglut
                      ];
        LD_LIBRARY_PATH="/run/opengl-driver/lib;${xorg.libX11}/lib/;${libGL}/lib/;${libGLU}/lib;${freeglut}/lib";
    };
}
