import x11/xlib, x11/xutil, x11/x, x11/keysym

const
  WINDOW_WIDTH = 800
  WINDOW_HEIGHT = 600
  DISPLAY_STRING = "Hello, Nimrods. Pepepains"

var
  display: PDisplay
  screen: cint
  win: TWindow
  wmDeleteMessage: TAtom
  running: bool

proc create_window =
  display = XOpenDisplay(nil)
  if display == nil:
    quit "Failed to open display"

  screen = XDefaultScreen(display)
  var rootwin = XRootWindow(display, screen)
  win = XCreateSimpleWindow(display, rootwin,
                            100, 10,
                            WINDOW_WIDTH, WINDOW_HEIGHT, 5,
                            XBlackPixel(display, screen),
                            XWhitePixel(display, screen))

  var size_hints = TXSizeHints(
    flags: PSize or PMinSize or PMaxSize,
    min_width: WINDOW_WIDTH.cint,
    max_width: WINDOW_WIDTH.cint,
    min_height: WINDOW_HEIGHT.cint,
    max_height: WINDOW_HEIGHT.cint)

  discard XSetStandardProperties(display,
                                 win,
                                 "Simple Window",
                                 "window",
                                 0, nil, 0,
                                 addr(size_hints))
  discard XSelectInput(display, win,
                       ButtonPressMask or KeyPressMask or
                       PointerMotionMask or ExposureMask)
  discard XMapWindow(display, win)

  wmDeleteMessage =
    XInternAtom(display,
                "WM_DELETE_WINDOW",
                false.TBool)

  discard XSetWMProtocols(display,
                          win,
                          wmDeleteMessage.addr, 1)
  running = true

proc close_window =
  discard XDestroyWindow(display, win)
  discard XCloseDisplay(display)

proc draw_screen =
  discard XDrawString(display, win,
                      DefaultGC(display, screen),
                      10, 50,
                      DISPLAY_STRING.cstring,
                      DISPLAY_STRING.len.cint)

proc handle_event =
  var xev: TXEvent
  discard XNextEvent(display, xev.addr)
  case xev.theType
  of Expose:
    draw_screen()
  of ClientMessage:
    if cast[TAtom](xev.xclient.data.l[0]) == wmDeleteMessage:
      running = false
  of KeyPress:
    var key = XLookupKeysym(cast[PXKeyEvent](xev.addr), 0)
    if key != 0:
      echo "Keyboard event"
  of ButtonPressMask, PointerMotionMask:
    echo "Mouse event"
  else:
    discard

create_window()
while running:
  handle_event()
close_window()
