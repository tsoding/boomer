import x11/xlib, x11/x

type Image* = PXImage

proc saveToPPM*(image: Image, filePath: string) =
  var f = open(filePath, fmWrite)
  defer: f.close
  writeLine(f, "P6")
  writeLine(f, image.width, " ", image.height)
  writeLine(f, 255)
  for i in 0..<(image.width * image.height):
    f.write(image.data[i * 4 + 2])
    f.write(image.data[i * 4 + 1])
    f.write(image.data[i * 4 + 0])

# NOTE: it's not possible to deallocate the returned Image because the
# reference to XImage is lost.
proc takeScreenshot*(display: PDisplay, root: TWindow): Image =
  var attributes: TXWindowAttributes
  discard XGetWindowAttributes(display, root, addr attributes)

  result = XGetImage(display, root,
                             0, 0,
                             attributes.width.cuint,
                             attributes.height.cuint,
                             AllPlanes,
                             ZPixmap)
  if result == nil:
    quit "Could not get a screenshot"
