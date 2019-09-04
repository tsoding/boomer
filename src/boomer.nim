import x11/xlib, x11/x, x11/xutil
import opengl, opengl/glx, opengl/glu

proc saveToPPM(filePath: string; pixels: cstring; width, height: cint) =
  var f = open(filePath, fmWrite)
  defer: f.close
  writeLine(f, "P6")
  writeLine(f, width, " ", height)
  writeLine(f, 255)
  for i in 0..<(width * height):
    f.write(pixels[i * 4 + 2])
    f.write(pixels[i * 4 + 1])
    f.write(pixels[i * 4 + 0])a

proc main() =
  var display = XOpenDisplay(nil)
  if display == nil:
    quit "Failed to open display"
  defer: discard XCloseDisplay(display)

  discard XSetErrorHandler(
    proc (display: PDisplay, error: PXErrorEvent): cint{.cdecl.} =
      echo "X error happend";
      return 0)

  var root = DefaultRootWindow(display)
  var attributes: TXWindowAttributes
  discard XGetWindowAttributes(display, root, addr attributes)

  var screenshot = XGetImage(display, root,
                             0, 0,
                             attributes.width.cuint,
                             attributes.height.cuint,
                             AllPlanes,
                             ZPixmap)
  discard XSync(display, 0)

  if screenshot == nil:
    quit "Could not get a screenshot"
  defer: discard XDestroyImage(screenshot)

  echo("Width: ", attributes.width)
  echo("Height: ", attributes.height)
  echo("BPP: ", screenshot.bits_per_pixel)

  saveToPPM("screenshot.ppm", screenshot.data, attributes.width, attributes.height)

main()
