[![Tsoding](https://img.shields.io/badge/twitch.tv-tsoding-purple?logo=twitch&style=for-the-badge)](https://www.twitch.tv/tsoding)
[![Build Status](https://travis-ci.org/tsoding/boomer.svg?branch=master)](https://travis-ci.org/tsoding/boomer)

# Boomer

Zoomer application for Linux.

- Development is done on https://twitch.tv/tsoding
- Archive of the streams: https://www.twitch.tv/collections/HlRy-q69uBXmpQ

**WARNING! The application is in an active development state and is
not even alpha yet. Use it at your own risk. Nothing is documented,
anything can be changed at any moment or stop working at all.**

## Quick Start

```console
$ nix-shell   # only for NixOS
$ nimble build
$ ./boomer
```

## Developer Capabilities

For additional Developer Capabilities compile the application with the following flags:

```console
$ nimble build -d:developer
```

This will enable:
- Reloading the shaders with `Ctrl+R`

## Experimental Live Update

See issue [#26]. For an experimental Live Update feature compile the application with the following flags:

```console
$ nimble build -d:live
```

For a faster Live Update feature based on MIT-SHM X11 extension use `-d:mitshm`:

```console
$ nimble build -d:live -d:mitshm
```

The MIT-SHM support would probably not work for you until
[nim-lang/x11#31](https://github.com/nim-lang/x11/pull/31) is merged.

The feature is really unstable and experimental, so use it at your own risk.

## NixOS Overlay

```
$ git clone git://github.com/tsoding/boomer.git /path/to/boomer
$ mkdir -p ~/.config/nixpkgs/overlays
$ cd ~/.config/nixpkgs/overlays
$ ln -s /path/to/boomer/overlay/ boomer
$ nix-env -iA nixos.boomer
```

## References

- https://github.com/nim-lang/x11/blob/bf9dc74dd196a98b7c2a2beea4d92640734f7c60/examples/x11ex.nim
- http://archive.xfce.org/src/xfce/xfwm4/4.13/
- https://www.khronos.org/opengl/wiki/Programming_OpenGL_in_Linux:_GLX_and_Xlib
- https://www.khronos.org/registry/OpenGL-Refpages/gl2.1/xhtml/glXIntro.xml
- https://stackoverflow.com/questions/24988164/c-fast-screenshots-in-linux-for-use-with-opencv
- https://github.com/lolilolicon/xrectsel
- https://github.com/naelstrof/slop
- https://www.x.org/releases/X11R7.7/doc/xextproto/shm.html
- http://netpbm.sourceforge.net/doc/ppm.html
- https://github.com/def-/nim-syscall

## Support

You can support my work via

- Twitch channel: https://www.twitch.tv/subs/tsoding
- Patreon: https://www.patreon.com/tsoding

[#26]: https://github.com/tsoding/boomer/issues/26
