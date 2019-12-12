import x11/xlib, x11/x, x11/xutil, x11/xshm
import syscall

const
  IPC_PRIVATE = 0
  IPC_CREAT = 512
  IPC_RMID = 0

type ScreenshotBackend* = enum
  DEFAULT,                  # XGetImage
  MITSHM                    # XShmGetImage

type Screenshot* = object
  backend*: ScreenshotBackend
  image*: PXImage
  shminfo*: PXShmSegmentInfo

proc newDefaultScreenshot*(display: PDisplay): Screenshot =
  result.backend = DEFAULT

  var root = DefaultRootWindow(display)
  var attributes: TXWindowAttributes
  discard XGetWindowAttributes(display, root, addr attributes)
  result.image = XGetImage(display, root,
                           0, 0,
                           attributes.width.cuint,
                           attributes.height.cuint,
                           AllPlanes,
                           ZPixmap)

proc newMitshmScreenshot*(display: PDisplay): Screenshot =
  result.backend = MITSHM
  result.shminfo = cast[PXShmSegmentInfo](allocShared(sizeof(TXShmSegmentInfo)))

  var root = DefaultRootWindow(display)
  var attributes: TXWindowAttributes
  discard XGetWindowAttributes(display, root, addr attributes)

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
  discard XShmGetImage(display, root, result.image, 0.cint, 0.cint, AllPlanes)

proc refresh*(screenshot: var Screenshot, display: PDisplay) =
  var root = DefaultRootWindow(display)

  case screenshot.backend
  of DEFAULT:
    screenshot.image =
      XGetSubImage(display, root,
                   0, 0,
                   screenshot.image.width.cuint,
                   screenshot.image.height.cuint,
                   AllPlanes,
                   ZPixmap,
                   screenshot.image,
                   0, 0)
  of MITSHM:
    discard XShmGetImage(
      display,
      root, screenshot.image,
      0.cint, 0.cint,
      AllPlanes)

proc destroy*(screenshot: var Screenshot, display: PDisplay) =
  case screenshot.backend
  of DEFAULT:
    discard XDestroyImage(screenshot.image)
  of MITSHM:
    discard XSync(display, 0)
    discard XShmDetach(display, screenshot.shminfo)
    discard XDestroyImage(screenshot.image)
    discard syscall(SHMDT, screenshot.shminfo.shmaddr)
    discard syscall(SHMCTL, screenshot.shminfo.shmid, IPC_RMID, 0)
    deallocShared(screenshot.shminfo)

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
