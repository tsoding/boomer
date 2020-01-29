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
$ nimble build
$ ./boomer --help
$ ./boomer          # to just start using
```

## Developer Capabilities

For additional Developer Capabilities compile the application with the following flags:

```console
$ nimble build -d:developer
```

This will enable:
- Reloading the shaders with `Ctrl+R`

## Controls

| Control                        | Description                                                   |
|--------------------------------|---------------------------------------------------------------|
| <kbd>0</kbd>                   | Reset the application state (position, scale, velocity, etc). |
| <kbd>q</kbd> or <kbd>ESC</kbd> | Quit the application.                                         |
| <kbd>r</kbd>                   | Reload configuration.                                         |
| <kbd>Ctrl</kbd> + <kbd>r</kbd> | Reload the shaders (only for Developer mode)                  |
| <kbd>f</kbd>                   | Toggle flashlight effect.                                     |
| Drag with left mouse button    | Move the image around.                                        |
| Scroll wheel                   | Zoom in/out.                                                  |
| <kbd>Ctrl</kbd> + Scroll wheel | Change the radious of the flaslight.                          |

## Experimental Features Compilation Flags

Experimental or unstable features can be enabled by passing the following flags to `nimble build` command:

| Flag          | Description                                                                                                                    |
|---------------|--------------------------------------------------------------------------------------------------------------------------------|
| `-d:live`     | Live image update. See issue [#26].                                                                                            |
| `-d:mitshm`   | Enables fater Live image update using MIT-SHM X11 extension. Should be used along with `-d:live` to have an effect             |
| `-d:select`   | Application lets the user to click on te window to "track" and it will track that specific window instead of the whole screen. |

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
- https://github.com/dreamer/scrot

## Support

You can support my work via

- Twitch channel: https://www.twitch.tv/subs/tsoding
- Patreon: https://www.patreon.com/tsoding

[#26]: https://github.com/tsoding/boomer/issues/26
