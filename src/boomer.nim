import x11/xlib, x11/x, x11/xutil
import opengl, opengl/glx, opengl/glu, opengl/glut
import macros

macro checkError(context: string): untyped =
  result = quote do:
    let error = glGetError()
    if error != 0.GLenum:
      echo "GL error ", error.GLint, " ", `context`

type Image* = object
  width, height, bpp: cint
  pixels: cstring

# TODO(#11): is there any way to make image not a global variable in GLUT?
var image: Image

proc saveToPPM(filePath: string, image: Image) =
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

  glBegin(GL_QUADS)
  glTexCoord2i(0, 0)
  glVertex2i(0, 0)
  glTexCoord2i(1, 0)
  glVertex2i(image.width, 0)
  glTexCoord2i(1, 1)
  glVertex2i(image.width, image.height)
  glTexCoord2i(0, 1)
  glVertex2i(0, image.height)
  glEnd()
  checkError("rasterizing the quadrangle")
  # TODO: there is no way to transform the image for the user

  glFlush()
  checkError("flush")

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
  image = takeScreenshot()

  assert image.bpp == 32

  var argc: cint = 0
  glutInit(addr argc, nil)
  # TODO(#7): how do you deinit glut?
  glutInitDisplayMode(GLUT_DOUBLE)
  # TODO(#8): the window should be the size of the screen
  glutInitWindowSize(image.width, image.height)
  glutInitWindowPosition(0, 0)
  discard glutCreateWindow("Wordpress Application")

  glutDisplayFunc(display)
  glutReshapeFunc(reshape)

  loadExtensions()

  var textures: GLuint = 0
  glGenTextures(1, addr textures)
  checkError("making texture")

  glBindTexture(GL_TEXTURE_2D, textures)
  checkError("binding texture")

  glTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGB.GLint,
               image.width,
               image.height,
               0,
               # TODO: the texture format is hardcoded
               GL_BGRA,
               GL_UNSIGNED_BYTE,
               image.pixels)
  checkError("loading texture")

  glEnable(GL_TEXTURE_2D)

  glOrtho(0.0,
          image.width.float,
          image.height.float,
          0.0,
          -1.0,
          1.0)
  checkError("setting transforms")

  glTexParameteri(GL_TEXTURE_2D,
                  GL_TEXTURE_MIN_FILTER,
                  GL_LINEAR)
  glTexParameteri(GL_TEXTURE_2D,
                  GL_TEXTURE_MAG_FILTER,
                  GL_LINEAR)

  glutMainLoop()

  # saveToPPM("screenshot.ppm", image)

main()
