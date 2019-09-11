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
var translateX: float = 0.0
var translateY: float = 0.0
var anchorX: float = 0.0
var anchorY: float = 0.0
var scale: float = 1.0

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
  glClearColor(0.0, 0.0, 0.0, 1.0)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

  glPushMatrix()

  glScalef(scale, scale, 1.0)
  glTranslatef(translateX, translateY, 0.0)

  glBegin(GL_QUADS)
  glTexCoord2i(0, 0)
  glVertex2f(image.width.float * -0.5, image.height.float * -0.5)

  glTexCoord2i(1, 0)
  glVertex2f(image.width.float * 0.5,  image.height.float * -0.5)

  glTexCoord2i(1, 1)
  glVertex2f(image.width.float * 0.5,  image.height.float * 0.5)

  glTexCoord2i(0, 1)
  glVertex2f(image.width.float * -0.5, image.height.float * 0.5)
  glEnd()
  checkError("rasterizing the quadrangle")
  # TODO(#12): there is no way to transform the image for the user

  glFlush()
  checkError("flush")

  glPopMatrix()

  glutSwapBuffers()

proc reshape(width: GLsizei, height: GLsizei) {.cdecl.} =
  discard

proc mouse(button, state, x, y: cint) {.cdecl.} =
  case state
  of GLUT_DOWN:
    anchorX = x.float - translateX
    anchorY = y.float - translateY
  else:
    discard

proc motion(x, y: cint) {.cdecl.} =
  # TODO: dragging does not take scale into account
  translateX = x.float - anchorX
  translateY = y.float - anchorY

# TODO: scaling should be done by scrolling mouse wheel
proc keyboard(c: int8, v1, v2: cint){.cdecl.} =
  case c
  of 'w'.ord:
    scale += 0.1
  of 's'.ord:
    scale -= 0.1
  else:
    discard

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

# TODO: replace GLUT with something where you are not required to do weird thing with timers
proc timer(x: cint) {.cdecl.} =
  glutPostRedisplay()
  glutTimerFunc(16, timer, 1)

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
  glutTimerFunc(16, timer, 1)
  glutMotionFunc(motion)
  glutKeyboardFunc(keyboard)
  glutMouseFunc(mouse)

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
               # TODO(#13): the texture format is hardcoded
               GL_BGRA,
               GL_UNSIGNED_BYTE,
               image.pixels)
  checkError("loading texture")

  glEnable(GL_TEXTURE_2D)

  glOrtho(image.width.float * -0.5,
          image.width.float * 0.5,
          image.height.float * 0.5,
          image.height.float * -0.5,
          -1.0, 1.0)
  checkError("setting transforms")

  glTexParameteri(GL_TEXTURE_2D,
                  GL_TEXTURE_MIN_FILTER,
                  GL_NEAREST)
  glTexParameteri(GL_TEXTURE_2D,
                  GL_TEXTURE_MAG_FILTER,
                  GL_NEAREST)

  glutMainLoop()

  # saveToPPM("screenshot.ppm", image)

main()
