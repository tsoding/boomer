import x11/xlib                 # of course
import x11/xutil
import x11/xshm
import x11/x

import syscall
import image

const
  IPC_PRIVATE = 0
  IPC_CREAT = 512
  IPC_RMID = 0

block:
  let display = XOpenDisplay(nil)
  defer:
    discard display.XCloseDisplay

  var major, minor: cint
  var pixmaps: TBool
  discard XShmQueryVersion(display, addr major, addr minor, addr pixmaps)
  echo "SHM Version ", major, ".", minor, ", Pixmaps supported: ", pixmaps

  var vinfo: TXVisualInfo
  discard XMatchVisualInfo(
    display,
    XDefaultScreen(display),
    24,
    TrueColor,
    addr vinfo)

  var attributes: TXWindowAttributes
  discard XGetWindowAttributes(
    display,
    DefaultRootWindow(display),
    addr attributes)

  var shminfo: TXShmSegmentInfo
  var image = XShmCreateImage(
    display, vinfo.visual, 24.cuint, ZPixmap, nil,
    addr shminfo,
    attributes.width.cuint,
    attributes.height.cuint)

  shminfo.shmid = syscall(SHMGET,
                          IPC_PRIVATE,
                          image.bytes_per_line * image.height,
                          1023).cint
  echo "shminfo.shmid = ", shminfo.shmid

  shminfo.shmaddr = cast[cstring](syscall(SHMAT, shminfo.shmid, 0, 0))
  image.data = shminfo.shmaddr
  shminfo.readOnly = 0

  let err = XShmAttach(display, addr shminfo)
  echo "Status of XShmAttach call = ", err
  discard XSync(display, 0)

  discard XShmGetImage(display, DefaultRootWindow(display), image, 0.cint, 0.cint, AllPlanes);
  discard XSync(display, 0);

  image.saveToPPM("nim-shmack.ppm")

  discard XShmDetach(display, addr shminfo)
  discard XDestroyImage(image)
  discard syscall(SHMDT, shminfo.shmaddr)
  discard syscall(SHMCTL, shminfo.shmid, IPC_RMID, 0)
