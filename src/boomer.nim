import x11/xlib, x11/x, x11/xutil
import opengl, opengl/glx
import math

import vec2
import navigation

const FPS: int = 60

template checkError(context: string) =
  let error = glGetError()
  if error != 0.GLenum:
    echo "GL error ", error.GLint, " ", context

type Image* = object
  width, height, bpp: cint
  pixels: cstring

# TODO(#11): is there any way to make image not a global variable in GLUT?
var image: Image
var camera = Camera(scale: 1.0)
var mouse: Mouse

var window: Vec2 = (0.0, 0.0)

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

  glScalef(camera.scale, camera.scale, 1.0)
  glTranslatef(camera.position.x, camera.position.y, 0.0)

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
        mouse.curr = (xev.xmotion.x.float,
                              xev.xmotion.y.float)

        if mouse.drag:
          camera.position += camera.world(mouse.curr) - camera.world(mouse.prev)
          camera.velocity = (mouse.curr - mouse.prev) * DRAG_VELOCITY_FACTOR
          mouse.prev = mouse.curr

      of ClientMessage:
        if cast[TAtom](xev.xclient.data.l[0]) == wmDeleteMessage:
          quitting = true

      of KeyPress:
        case xev.xkey.keycode
        of 19:
          camera.scale = 1.0
          camera.delta_scale = 0.0
          camera.position = (0.0, 0.0)
          camera.velocity = (0.0, 0.0)
        else:
          discard

      of ButtonPress:
        case xev.xbutton.button
        of LEFT_BUTTON:
          mouse.prev = mouse.curr
          mouse.drag = true

        of WHEEL_UP:
          camera.delta_scale += SCROLL_SPEED

        of WHEEL_DOWN:
          camera.delta_scale -= SCROLL_SPEED

        else:
          discard

      of ButtonRelease:
        case xev.xbutton.button
        of LEFT_BUTTON:
          mouse.drag = false
        else:
          discard
      else:
        discard

    camera.update(1.0 / FPS.float, mouse)
    display()

    glXSwapBuffers(display, win)

  # saveToPPM("screenshot.ppm", image)

main()
