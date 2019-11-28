{ stdenv, fetchFromGitHub, nim, libX11, libGL, freeglut, nim_1_0 }:

let
  x11-nim = fetchFromGitHub {
    owner = "nim-lang";
    repo = "x11";
    rev = "3dd8f523fb2b502f4e5a958d8acf09a0b8ac0452";
    sha256 = "0zaarwii6h3njl96kwrv8ag3hfy60lyw2x5dg37fdplhkywdic66";
  };
  opengl-nim = fetchFromGitHub {
    owner = "nim-lang";
    repo = "opengl";
    rev = "f51db493faca670576afffe2117d59b80f934394";
    sha256 = "1k3nxad0q74nynxi4l21ix9jwn5w1gpvpgynzp9v90x22n3k85hb";
  };
in stdenv.mkDerivation rec {
  pname = "boomer";
  version = "unstable-2019-11-28";
  src = fetchFromGitHub {
    owner = "tsoding";
    repo = "boomer";
    rev = "e631ef22d7c79d71bb955e1467f4400594233408";
    sha256 = "0pnygv0a8z1shmdad9kn6wyda7bv5rblh1qg64fd9rwiwf5dfn9c";
  };
  buildInputs = [ nim_1_0 libX11 libGL freeglut ];
  buildPhase = ''
    HOME=$TMPDIR
    nim -p:${x11-nim}/ -p:${opengl-nim}/src c -d:release src/boomer.nim
  '';
  installPhase = "install -Dt $out/bin src/boomer";
  fixupPhase = "patchelf --set-rpath ${stdenv.lib.makeLibraryPath [stdenv.cc.cc libX11 libGL freeglut]} $out/bin/boomer";
}
