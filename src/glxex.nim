import x11/xlib, x11/x
import opengl, opengl/glx

proc main() =
  var display = XOpenDisplay(nil)
  if display == nil:
    quit "Failed to open display"
  let screen = XDefaultScreen(display)

  var glxMajor : int
  var glxMinor : int

  if (not glXQueryVersion(display, glxMajor, glxMinor) or
      (glxMajor == 1 and glxMinor < 3) or
      (glxMajor < 1)):
    quit "Invalid GLX version. Expected >=1.3"
  
  echo("GLX version ", glxMajor, ".", glxMinor)

  echo("GLX extension: ", $glXQueryExtensionsString(display, screen))

  var att = [GLX_RGBA, GLX_DEPTH_SIZE, 24, GLX_DOUBLEBUFFER, None]

  var root = DefaultRootWindow(display)
  var vi = glXChooseVisual(display, 0, addr att[0])

  if (vi == nil):
    quit "No appropriate visual found"

  echo("Visual ", vi.visualid, " selected")

  var cmap = XCreateColormap(display, root, vi.visual, AllocNone)
  var swa: TXSetWindowAttributes
  swa.colormap = cmap
  swa.event_mask = ExposureMask or KeyPressMask

  var win = XCreateWindow(
    display, root, 0, 0, 600, 600, 0,
    vi.depth, InputOutput, vi.visual,
    CWColormap or CWEventMask, addr swa)

  discard XMapWindow(display, win)

  discard XStoreName(display, win, "Wordpress Application")

  var glc = glXCreateContext(display, vi, nil, GL_TRUE)

  discard glXMakeCurrent(display, win, glc)

  loadExtensions()

  glEnable(GL_DEPTH_TEST)

  var xev: TXEvent

  while true:
    discard XNextEvent(display, addr xev)

    case xev.theType
    of Expose:
      var gwa: TXWindowAttributes
      discard XGetWindowAttributes(display, win, addr gwa)
      glViewport(0, 0, gwa.width, gwa.height)
      # Draw Something
      glXSwapBuffers(display, win)
    of KeyPress:
      discard glXMakeCurrent(display, None, nil)
      glXDestroyContext(display, glc)
      discard XDestroyWindow(display, win)
      discard XCloseDisplay(display)
      quit "done"
    else:
      discard

main()
