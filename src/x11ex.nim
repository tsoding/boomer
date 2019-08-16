import x11/xlib, x11/xutil, x11/x, x11/keysym

type
  Hello* = object
    running*: bool
    display: PDisplay
    screen: cint
    win: TWindow
    wmDeleteMessage: TAtom
    message: cstring

proc create_hello*(width, height: int,
                   message: string): Hello =
  result.message = message
  result.display = XOpenDisplay(nil)
  if result.display == nil:
    quit "Failed to open display"

  result.screen = XDefaultScreen(result.display)
  var rootwin = XRootWindow(result.display, result.screen)
  result.win =
    XCreateSimpleWindow(result.display, rootwin,
                        100, 10,
                        width.cuint, height.cuint, 5,
                        XBlackPixel(result.display,
                                    result.screen),
                        XWhitePixel(result.display,
                                    result.screen))

  var size_hints = TXSizeHints(
    flags: PSize or PMinSize or PMaxSize,
    min_width: width.cint,
    max_width: width.cint,
    min_height: height.cint,
    max_height: height.cint)

  discard XSetStandardProperties(result.display,
                                 result.win,
                                 "Simple Window",
                                 "window",
                                 0, nil, 0,
                                 addr(size_hints))
  discard XSelectInput(result.display, result.win,
                       ButtonPressMask or KeyPressMask or
                       PointerMotionMask or ExposureMask)
  discard XMapWindow(result.display, result.win)

  result.wmDeleteMessage =
    XInternAtom(result.display,
                "WM_DELETE_WINDOW",
                false.TBool)

  discard XSetWMProtocols(result.display,
                          result.win,
                          result.wmDeleteMessage.addr, 1)
  result.running = true

proc close* (hello: Hello) =
  discard XDestroyWindow(hello.display, hello.win)
  discard XCloseDisplay(hello.display)

proc draw* (hello: Hello) =
  discard XDrawString(hello.display,
                      hello.win,
                      DefaultGC(hello.display, hello.screen),
                      10, 50,
                      hello.message,
                      hello.message.len.cint)

proc handle_event* (hello: var Hello) =
  var xev: TXEvent
  discard XNextEvent(hello.display, xev.addr)
  case xev.theType
  of Expose:
    hello.draw()
  of ClientMessage:
    if cast[TAtom](xev.xclient.data.l[0]) == hello.wmDeleteMessage:
      hello.running = false
  of KeyPress:
    var key = XLookupKeysym(cast[PXKeyEvent](xev.addr), 0)
    if key != 0:
      echo "Keyboard event"
  of ButtonPressMask, PointerMotionMask:
    echo "Mouse event"
  else:
    discard

block:
  var hello = createHello(800, 600, "Hello!")
  defer: hello.close()
  while hello.running:
    hello.handle_event()
