with import <nixpkgs> {}; {
    boomerEnv = stdenv.mkDerivation {
        name = "boomer-env";
        buildInputs = [ stdenv
                        gcc
                        pkgconfig
                        nim
                      ];
    };
}
