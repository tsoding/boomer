import x11/xlib, x11/x, x11/xutil
import opengl, opengl/glx
import math

const FPS: int = 60
const SCROLL_SPEED = 0.1
const DRAG_VELOCITY_FACTOR: float = 20.0
const FRICTION: float = 2000.0

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
var camera_position: Vec2 = (0.0, 0.0)
var camera_prev: Vec2 = (0.0, 0.0)
var camera_velocity: Vec2 = (0.0, 0.0)
var camera_scale = 1.0
var camera_delta_scale = 0.0
var mouse_position = (0.0, 0.0)

var window: Vec2 = (0.0, 0.0)
var drag: bool = false

proc `-`(v1: Vec2, v2: Vec2): Vec2 {.inline.} = (v1.x - v2.x, v1.y - v2.y)
proc `+`(v1: Vec2, v2: Vec2): Vec2 {.inline.} = (v1.x + v2.x, v1.y + v2.y)
proc `*`(v: Vec2, s: float): Vec2 {.inline.} = (v.x * s, v.y * s)
proc `/`(v: Vec2, s: float): Vec2 {.inline.} = (v.x / s, v.y / s)
proc `+=`(v1: var Vec2, v2: Vec2) {.inline.} =
  v1.x += v2.x
  v1.y += v2.y
proc `*=`(v: var Vec2, s: float) {.inline.} =
  v.x *= s
  v.y *= s

proc len(v: Vec2): float =
  sqrt(v.x * v.x + v.y * v.y)

proc norm(v: Vec2): Vec2 =
  let l = v.len
  if abs(l) < 1e-9:
    result = (0.0, 0.0)
  else:
    result = (v.x / l, v.y / l)

proc screen(v: Vec2): Vec2 =
  v * camera_scale + camera_position

proc world(v: Vec2): Vec2 =
  (v - camera_position) / camera_scale

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

proc display() =
  glClearColor(0.0, 0.0, 0.0, 1.0)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

  glPushMatrix()

  glScalef(camera_scale, camera_scale, 1.0)
  glTranslatef(camera_position.x, camera_position.y, 0.0)

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

proc update(dt: float) =
  echo camera_velocity.len

  if abs(camera_delta_scale) > 0.5:
    let wp0 = mouse_position.world
    camera_scale = max(camera_scale + camera_delta_scale * dt, 1.0)
    let wp1 = mouse_position.world
    let dwp = wp1 - wp0
    camera_position += dwp
    camera_delta_scale -= sgn(camera_delta_scale).float * 5.0 * dt

  if not drag and (camera_velocity.len > 20.0):
    camera_position += camera_velocity * dt
    camera_velocity = camera_velocity - camera_velocity.norm * FRICTION * dt

# TODO(#29): get rid of custom X11 button constants
const
  LEFT_BUTTON = 1
  WHEEL_UP = 4
  WHEEL_DOWN = 5

# NOTE: it's not possible to deallocate the returned Image because the
# reference to XImage is lost.
proc takeScreenshot(display: PDisplay, root: TWindow): Image =
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

proc main() =
  var display = XOpenDisplay(nil)
  if display == nil:
    quit "Failed to open display"
  defer:
    discard XCloseDisplay(display)

  var root = DefaultRootWindow(display)

  image = takeScreenshot(display, root)
  assert image.bpp == 32

  let screen = XDefaultScreen(display)
  var glxMajor : int
  var glxMinor : int

  if (not glXQueryVersion(display, glxMajor, glxMinor) or
      (glxMajor == 1 and glxMinor < 3) or
      (glxMajor < 1)):
    quit "Invalid GLX version. Expected >=1.3"
  echo("GLX version ", glxMajor, ".", glxMinor)
  echo("GLX extension: ", $glXQueryExtensionsString(display, screen))

  var attrs = [
    GLX_RGBA,
    GLX_DEPTH_SIZE, 24,
    GLX_DOUBLEBUFFER,
    None]

  var vi = glXChooseVisual(display, 0, addr attrs[0])
  if vi == nil:
    quit "No appropriate visual found"

  echo "Visual ", vi.visualid, " selected"
  var swa: TXSetWindowAttributes
  swa.colormap = XCreateColormap(display, root,
                                 vi.visual, AllocNone)
  swa.event_mask = ButtonPressMask or ButtonReleaseMask or KeyPressMask or
                   PointerMotionMask or ExposureMask or ClientMessage

  # TODO(#8): the window should be the size of the screen
  var win = XCreateWindow(
    display, root,
    0, 0, image.width.cuint, image.height.cuint, 0,
    vi.depth, InputOutput, vi.visual,
    CWColormap or CWEventMask, addr swa)

  discard XMapWindow(display, win)
  discard XStoreName(display, win, "Wordpress Application")

  var wmDeleteMessage = XInternAtom(
    display, "WM_DELETE_WINDOW",
    false.TBool)

  discard XSetWMProtocols(display, win,
                          addr wmDeleteMessage, 1)

  var glc = glXCreateContext(display, vi, nil, GL_TRUE)
  discard glXMakeCurrent(display, win, glc)

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

  glViewport(0, 0, image.width, image.height)
  var quitting = false
  while not quitting:
    var xev: TXEvent
    while XPending(display) > 0:
      discard XNextEvent(display, addr xev)
      case xev.theType
      of Expose:
        discard

      of MotionNotify:
        mouse_position = (xev.xmotion.x.float,
                          xev.xmotion.y.float)

        if drag:
          camera_position += mouse_position.world - camera_prev.world
          camera_velocity = (mouse_position - camera_prev) * DRAG_VELOCITY_FACTOR
          camera_prev = mouse_position

      of ClientMessage:
        if cast[TAtom](xev.xclient.data.l[0]) == wmDeleteMessage:
          quitting = true

      of KeyPress:
        case xev.xkey.keycode
        of 19:
          camera_scale = 1.0
          camera_delta_scale = 0.0
          camera_position = (0.0, 0.0)
          camera_velocity = (0.0, 0.0)
        else:
          discard

      of ButtonPress:
        case xev.xbutton.button
        of LEFT_BUTTON:
          camera_prev = mouse_position
          drag = true

        of WHEEL_UP:
          camera_delta_scale += 1.0

        of WHEEL_DOWN:
          camera_delta_scale -= 1.0

        else:
          discard

      of ButtonRelease:
        case xev.xbutton.button
        of LEFT_BUTTON:
          drag = false
        else:
          discard
      else:
        discard

    update(1.0 / FPS.float)
    display()

    glXSwapBuffers(display, win)

  # saveToPPM("screenshot.ppm", image)

main()
