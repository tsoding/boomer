import x11/xlib, x11/xutil, x11/x, x11/keysym

const
  WINDOW_WIDTH = 800
  WINDOW_HEIGHT = 600

var
  # TODO: why do we need this shit here? REeeee
  width, height: cuint
  display: PDisplay
  screen: cint
  depth: int
  win: TWindow
  sizeHints: TXSizeHints
  wmDeleteMessage: TAtom
  running: bool
  xev: TXEvent
  display_string = "Hello, Nimrods. Pepepains"

proc create_window =
  width = WINDOW_WIDTH
  height = WINDOW_HEIGHT

  display = XOpenDisplay(nil)
  if display == nil:
    quit "Failed to open display"

  screen = XDefaultScreen(display)
  depth = XDefaultDepth(display, screen)
  var rootwin = XRootWindow(display, screen)
  win = XCreateSimpleWindow(display, rootwin,
                            100, 10,
                            width, height, 5,
                            XBlackPixel(display, screen),
                            XWhitePixel(display, screen))
  size_hints.flags = PSize or PMinSize or PMaxSize
  size_hints.min_width = width.cint
  size_hints.max_width = width.cint
  size_hints.min_height = height.cint
  size_hints.max_height = height.cint

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
                      displayString.cstring,
                      displayString.len.cint)

proc handle_event =
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
