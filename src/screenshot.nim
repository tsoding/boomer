import x11/xlib, x11/x, x11/xutil

when defined(mitshm):
  import x11/xshm

  # Stolen from https://github.com/def-/nim-syscall
  when defined(amd64):
    type Number = enum
      SHMGET = 29
      SHMAT = 30
      SHMCTL = 31
      SHMDT = 67

    proc syscall*(n: Number, a1: any): clong {.inline.} =
      {.emit: """asm volatile(
        "syscall" : "=a"(`result`)
                  : "a"((long)`n`), "D"((long)`a1`)
                  : "memory", "r11", "rcx", "cc");""".}

    proc syscall*(n: Number, a1, a2, a3: any): clong {.inline.} =
      {.emit: """asm volatile(
        "syscall" : "=a"(`result`)
                  : "a"((long)`n`), "D"((long)`a1`), "S"((long)`a2`),
                     "d"((long)`a3`)
                  : "memory", "r11", "rcx", "cc");""".}
  else:
    {.error: "Supported only Linux x86_64. Feel free to submit a PR to https://github.com/tsoding/boomer to fix it.".}

  const
    IPC_PRIVATE = 0
    IPC_CREAT = 512
    IPC_RMID = 0

type Screenshot* = object
  image*: PXImage
  when defined(mitshm):
    shminfo*: PXShmSegmentInfo

proc newScreenshot*(display: PDisplay, window: Window): Screenshot =
  var attributes: XWindowAttributes
  discard XGetWindowAttributes(display, window, addr attributes)

  when defined(mitshm):
    result.shminfo = cast[PXShmSegmentInfo](
      allocShared(sizeof(TXShmSegmentInfo)))
    let screen = DefaultScreen(display)
    result.image = XShmCreateImage(
      display,
      DefaultVisual(display, screen),
      DefaultDepthOfScreen(ScreenOfDisplay(display, screen)).cuint,
      ZPixmap,
      nil,
      result.shminfo,
      attributes.width.cuint,
      attributes.height.cuint)

    result.shminfo.shmid = syscall(
      SHMGET,
      IPC_PRIVATE,
      result.image.bytes_per_line * result.image.height,
      IPC_CREAT or 0o777).cint

    result.shminfo.shmaddr = cast[cstring](syscall(
      SHMAT,
      result.shminfo.shmid,
      0, 0))
    result.image.data = result.shminfo.shmaddr
    result.shminfo.readOnly = 0

    discard XShmAttach(display, result.shminfo)
    discard XShmGetImage(
      display, window, result.image, 0.cint, 0.cint, AllPlanes)
  else:
    result.image = XGetImage(
      display, window,
      0, 0,
      attributes.width.cuint,
      attributes.height.cuint,
      AllPlanes,
      ZPixmap)

proc destroy*(screenshot: Screenshot, display: PDisplay) =
  when defined(mitshm):
    discard XSync(display, 0)
    discard XShmDetach(display, screenshot.shminfo)
    discard XDestroyImage(screenshot.image)
    discard syscall(SHMDT, screenshot.shminfo.shmaddr)
    discard syscall(SHMCTL, screenshot.shminfo.shmid, IPC_RMID, 0)
    deallocShared(screenshot.shminfo)
  else:
    discard XDestroyImage(screenshot.image)

# TODO(#92): there is too much X11 error logging when the tracked live update window is resized
proc refresh*(screenshot: var Screenshot, display: PDisplay, window: Window) =
  var attributes: XWindowAttributes
  discard XGetWindowAttributes(display, window, addr attributes)

  when defined(mitshm):
    if XShmGetImage(display,
                    window, screenshot.image,
                    0.cint, 0.cint,
                    AllPlanes) == 0 or
       attributes.width != screenshot.image.width or
       attributes.height != screenshot.image.height:
      screenshot.destroy(display)
      screenshot = newScreenshot(display, window)
  else:
    let refreshedImage = XGetSubImage(
      display, window,
      0, 0,
      screenshot.image.width.cuint,
      screenshot.image.height.cuint,
      AllPlanes,
      ZPixmap,
      screenshot.image,
      0, 0)
    if refreshedImage == nil or
       refreshedImage.width != attributes.width or
       refreshedImage.height != attributes.height:
      let newImage = XGetImage(
        display, window,
        0, 0,
        attributes.width.cuint,
        attributes.height.cuint,
        AllPlanes,
        ZPixmap)

      if newImage != nil:
        discard XDestroyImage(screenshot.image)
        screenshot.image = newImage
    else:
      screenshot.image = refreshedImage

proc saveToPPM*(image: PXImage, filePath: string) =
  var f = open(filePath, fmWrite)
  defer: f.close
  writeLine(f, "P6")
  writeLine(f, image.width, " ", image.height)
  writeLine(f, 255)
  for i in 0..<(image.width * image.height):
    f.write(image.data[i * 4 + 2])
    f.write(image.data[i * 4 + 1])
    f.write(image.data[i * 4 + 0])
