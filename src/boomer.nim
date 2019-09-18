import x11/xlib, x11/x, x11/xutil
import opengl, opengl/glx, opengl/glu, opengl/glut

const FPS = 60
const SCROLL_SPEED = 0.1

template checkError(context: string) =
  let error = glGetError()
  if error != 0.GLenum:
    echo "GL error ", error.GLint, " ", context

type Vec2 = tuple[x: float, y: float]

type Image* = object
  width, height, bpp: cint
  pixels: cstring

# TODO(#11): is there any way to make image not a global variable in GLUT?
var image: Image
var translate: Vec2 = (0.0, 0.0)
var prev: Vec2 = (0.0, 0.0)
var scale = 1.0
var window: Vec2 = (0.0, 0.0)

proc `-`(v1: Vec2, v2: Vec2): Vec2 {.inline.} = (v1.x - v2.x, v1.y - v2.y)
proc `+`(v1: Vec2, v2: Vec2): Vec2 {.inline.} = (v1.x + v2.x, v1.y + v2.y)
proc `*`(v: Vec2, s: float): Vec2 {.inline.} = (v.x * s, v.y * s)
proc `/`(v: Vec2, s: float): Vec2 {.inline.} = (v.x / s, v.y / s)
proc `+=`(v1: var Vec2, v2: Vec2) {.inline.} =
  v1.x += v2.x
  v1.y += v2.y

proc screen(v: Vec2): Vec2 =
  v * scale + translate

proc world(v: Vec2): Vec2 =
  (v - translate) / scale

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
  glTranslatef(translate.x, translate.y, 0.0)

  glBegin(GL_QUADS)
  glTexCoord2i(0, 0)
  glVertex2f(0.0, 0.0)

  glTexCoord2i(1, 0)
  glVertex2f(image.width.float, 0.0)

  glTexCoord2i(1, 1)
  glVertex2f(image.width.float, image.height.float)

  glTexCoord2i(0, 1)
  glVertex2f(0.0, image.height.float)
  glEnd()
  checkError("rasterizing the quadrangle")

  glFlush()
  checkError("flush")

  glPopMatrix()

  glutSwapBuffers()

proc reshape(width: GLsizei, height: GLsizei) {.cdecl.} =
  echo "reshape ", width, " ", height
  window = (width.float, height.float)

const
  GLUT_WHEEL_UP = 3
  GLUT_WHEEL_DOWN = 4

proc mouse(button, state, x, y: cint) {.cdecl.} =
  echo "mouse: ", button, " ", state, " ", x, " ", y
  let p: Vec2 = (x.float, y.float)

  # TODO(#23): mouse scrolling is very X11 specific (despite using GLUT)
  #   We rely on scrolling being reported as pressing mouse buttons 3
  #   and 4. May not work on other platforms.
  case state:
  of GLUT_DOWN:
    case button:
    of GLUT_LEFT_BUTTON:
      prev = p
    of GLUT_WHEEL_UP:
      let wp0 = p.world
      scale += SCROLL_SPEED
      let wp1 = p.world
      let dwp = wp1 - wp0
      translate += dwp
    of GLUT_WHEEL_DOWN:
      let wp0 = p.world
      scale -= SCROLL_SPEED
      let wp1 = p.world
      let dwp = wp1 - wp0
      translate += dwp
    else:
      discard
  else:
    discard

# TODO: try adding inertia to the dragging
#   Dragging fills a little bit stiff. Let's try to add some inertia
#   with easing out.
proc motion(x, y: cint) {.cdecl.} =
  let current: Vec2 = (x.float, y.float)
  translate += current.world - prev.world
  prev = current

proc keyboard(c: int8, v1, v2: cint) {.cdecl.} =
  echo "keyboard ", c, " ", v1, " ", v2 
  case c:
  of '0'.ord:
    scale = 1.0
    translate = (0.0, 0.0)
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

# TODO(#17): replace GLUT with something where you are not required to do weird thing with timers
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
  glutTimerFunc(1000 div FPS, timer, 1)
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

  glOrtho(0.0, image.width.float,
          image.height.float, 0.0,
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
