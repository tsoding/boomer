import x11/xlib, x11/x, x11/xutil

type Image* = object
  width*, height*, bpp*: cint
  pixels*: cstring

proc saveToPPM*(image: Image, filePath: string) =
  var f = open(filePath, fmWrite)
  defer: f.close
  writeLine(f, "P6")
  writeLine(f, image.width, " ", image.height)
  writeLine(f, 255)
  for i in 0..<(image.width * image.height):
    f.write(image.pixels[i * 4 + 2])
    f.write(image.pixels[i * 4 + 1])
    f.write(image.pixels[i * 4 + 0])

# NOTE: it's not possible to deallocate the returned Image because the
# reference to XImage is lost.
proc takeScreenshot*(display: PDisplay, root: TWindow): Image =
  var attributes: TXWindowAttributes
  discard XGetWindowAttributes(display, root, addr attributes)

  var screenshot = XGetImage(display, root,
                             0, 0,
                             attributes.width.cuint,
                             attributes.height.cuint,
                             AllPlanes,
                             ZPixmap)
  if screenshot == nil:
    quit "Could not get a screenshot"

  result.width = attributes.width
  result.height = attributes.height
  result.bpp = screenshot.bits_per_pixel
  result.pixels = screenshot.data
