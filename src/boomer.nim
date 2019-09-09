import x11/xlib, x11/x, x11/xutil
import opengl, opengl/glx, opengl/glu, opengl/glut

type Image* = object
  width, height, bpp: cint
  pixels: cstring

proc saveToPPM(filePath: string; image: Image) =
  var f = open(filePath, fmWrite)
  defer: f.close
  writeLine(f, "P6")
  writeLine(f, image.width, " ", image.height)
  writeLine(f, 255)
  for i in 0..<(image.width * image.height):
    f.write(image.pixels[i * 4 + 2])
    f.write(image.pixels[i * 4 + 1])
    f.write(image.pixels[i * 4 + 0])

proc display() {.cdecl.} =
  glClearColor(1.0, 0.0, 0.0, 1.0)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

  glutSwapBuffers()

proc reshape(width: GLsizei, height: GLsizei) {.cdecl.} =
  if height == 0:
    return
  glViewport(0, 0, width, height)

# NOTE: it's not possible to deallocate the returned Image because the
# reference to XImage is lost.
proc takeScreenshot(): Image =
  var display = XOpenDisplay(nil)
  if display == nil:
    quit "Failed to open display"

  var root = DefaultRootWindow(display)
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

  discard XCloseDisplay(display)

  result.width = attributes.width
  result.height = attributes.height
  result.bpp = screenshot.bits_per_pixel
  result.pixels = screenshot.data

proc main() =
  let image = takeScreenshot()

  assert image.bpp == 32

  var argc: cint = 0;
  glutInit(addr argc, nil)
  # TODO(#7): how do you deinit glut?
  glutInitDisplayMode(GLUT_DOUBLE)
  # TODO(#8): the window should be the size of the screen
  glutInitWindowSize(640, 480)
  glutInitWindowPosition(0, 0)
  discard glutCreateWindow("Wordpress Application")

  glutDisplayFunc(display)
  glutReshapeFunc(reshape)

  loadExtensions()

  # TODO: the screenshot image is not rendered

  glutMainLoop()

  # saveToPPM("screenshot.ppm", screenshot.data, attributes.width, attributes.height)

main()
