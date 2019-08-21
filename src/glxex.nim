import x11/xlib
import opengl/glx

proc main() =
  var display = XOpenDisplay(nil)
  if display == nil:
    quit "Failed to open display"

  var glxMajor : int
  var glxMinor : int

  discard glXQueryVersion(display, glxMajor, glxMinor)
  echo("GLX version ", glxMajor, ".", glxMinor)

main()
