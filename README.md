[![Tsoding](https://img.shields.io/badge/twitch.tv-tsoding-purple?logo=twitch&style=for-the-badge)](https://www.twitch.tv/tsoding)
[![Build Status](https://travis-ci.org/tsoding/boomer.svg?branch=master)](https://travis-ci.org/tsoding/boomer)

# Boomer

![](./demo.gif)

Zoomer application for Linux.

- Development is done on https://twitch.tv/tsoding
- Archive of the streams: https://www.twitch.tv/collections/HlRy-q69uBXmpQ

## Dependencies

### Debian

```console
$ sudo apt-get install libgl1-mesa-dev libx11-dev libxext-dev libxrandr-dev
```

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

This will enable reloading the shaders with `Ctrl+R`. The shader files (`frag.glsl` and `vert.glsl`) should be located in the same folder as `boomer.nim` for this feature to work. If the shader files not found the program won't even start.

**Keep in mind that the developer build is not suitable for day-to-day usage because it creates the external dependency on the shader files. Compiling the program without `-d:developer` "bakes" the shaders into the executable and eliminates the dependency.**

## Controls

| Control                                   | Description                                                   |
|-------------------------------------------|---------------------------------------------------------------|
| <kbd>0</kbd>                              | Reset the application state (position, scale, velocity, etc). |
| <kbd>q</kbd> or <kbd>ESC</kbd>            | Quit the application.                                         |
| <kbd>r</kbd>                              | Reload configuration.                                         |
| <kbd>Ctrl</kbd> + <kbd>r</kbd>            | Reload the shaders (only for Developer mode)                  |
| <kbd>f</kbd>                              | Toggle flashlight effect.                                     |
| Drag with left mouse button               | Move the image around.                                        |
| Scroll wheel or <kbd>=</kbd>/<kbd>-</kbd> | Zoom in/out.                                                  |
| <kbd>Ctrl</kbd> + Scroll wheel            | Change the radious of the flaslight.                          |

## Configuration

Configuration file is located at `$HOME/.config/boomer/config` and has roughly the following format:

```
<param-1> = <value-1>
<param-2> = <value-2>
# comment
<param-3> = <value-3>
```

You can generate a new config at `$HOME/.config/boomer/config` with `$ boomer --new-config`.

Supported parameters:

| Name           | Description                                        |
|----------------|----------------------------------------------------|
| min_scale      | The smallest it can get when zooming out           |
| scroll_speed   | How quickly you can zoom in/out by scrolling       |
| drag_friction  | How quickly the movement slows down after dragging |
| scale_friction | How quickly the zoom slows down after scrolling    |

## Experimental Features Compilation Flags

Experimental or unstable features can be enabled by passing the following flags to `nimble build` command:

| Flag          | Description                                                                                                                    |
|---------------|--------------------------------------------------------------------------------------------------------------------------------|
| `-d:live`     | Live image update. See issue [#26].                                                                                            |
| `-d:mitshm`   | Enables faster Live image update using MIT-SHM X11 extension. Should be used along with `-d:live` to have an effect             |
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
