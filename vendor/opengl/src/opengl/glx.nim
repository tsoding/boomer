#
#
#  Translation of the Mesa GLX headers for FreePascal
#  Copyright (C) 1999 Sebastian Guenther
#
#
#  Mesa 3-D graphics library
#  Version:  3.0
#  Copyright (C) 1995-1998  Brian Paul
#

import x11/x, x11/xlib, x11/xutil, opengl

{.deadCodeElim: on.}

when defined(windows):
  const
    dllname = "GL.dll"
elif defined(macosx):
  const
    dllname = "/usr/X11R6/lib/libGL.dylib"
elif defined(linux):
  const
    dllname = "libGL.so.1"
else:
  const
    dllname = "libGL.so"
const
  GLX_USE_GL* = 1'i32
  GLX_BUFFER_SIZE* = 2'i32
  GLX_LEVEL* = 3'i32
  GLX_RGBA* = 4'i32
  GLX_DOUBLEBUFFER* = 5'i32
  GLX_STEREO* = 6'i32
  GLX_AUX_BUFFERS* = 7'i32
  GLX_RED_SIZE* = 8'i32
  GLX_GREEN_SIZE* = 9'i32
  GLX_BLUE_SIZE* = 10'i32
  GLX_ALPHA_SIZE* = 11'i32
  GLX_DEPTH_SIZE* = 12'i32
  GLX_STENCIL_SIZE* = 13'i32
  GLX_ACCUM_RED_SIZE* = 14'i32
  GLX_ACCUM_GREEN_SIZE* = 15'i32
  GLX_ACCUM_BLUE_SIZE* = 16'i32
  GLX_ACCUM_ALPHA_SIZE* = 17'i32  # GLX_EXT_visual_info extension
  GLX_X_VISUAL_TYPE_EXT* = 0x00000022
  GLX_TRANSPARENT_TYPE_EXT* = 0x00000023
  GLX_TRANSPARENT_INDEX_VALUE_EXT* = 0x00000024
  GLX_TRANSPARENT_RED_VALUE_EXT* = 0x00000025
  GLX_TRANSPARENT_GREEN_VALUE_EXT* = 0x00000026
  GLX_TRANSPARENT_BLUE_VALUE_EXT* = 0x00000027
  GLX_TRANSPARENT_ALPHA_VALUE_EXT* = 0x00000028 # Error codes returned by glXGetConfig:
  GLX_BAD_SCREEN* = 1
  GLX_BAD_ATTRIBUTE* = 2
  GLX_NO_EXTENSION* = 3
  GLX_BAD_VISUAL* = 4
  GLX_BAD_CONTEXT* = 5
  GLX_BAD_VALUE* = 6
  GLX_BAD_ENUM* = 7           # GLX 1.1 and later:
  GLX_VENDOR* = 1
  GLX_VERSION* = 2
  GLX_EXTENSIONS* = 3         # GLX_visual_info extension
  GLX_TRUE_COLOR_EXT* = 0x00008002
  GLX_DIRECT_COLOR_EXT* = 0x00008003
  GLX_PSEUDO_COLOR_EXT* = 0x00008004
  GLX_STATIC_COLOR_EXT* = 0x00008005
  GLX_GRAY_SCALE_EXT* = 0x00008006
  GLX_STATIC_GRAY_EXT* = 0x00008007
  GLX_NONE_EXT* = 0x00008000
  GLX_TRANSPARENT_RGB_EXT* = 0x00008008
  GLX_TRANSPARENT_INDEX_EXT* = 0x00008009

type                          # From XLib:
  XPixmap* = XID
  XFont* = XID
  XColormap* = XID
  GLXContext* = pointer
  GLXPixmap* = XID
  GLXDrawable* = XID
  GLXContextID* = XID
  TXPixmap* = XPixmap
  TXFont* = XFont
  TXColormap* = XColormap
  TGLXContext* = GLXContext
  TGLXPixmap* = GLXPixmap
  TGLXDrawable* = GLXDrawable
  TGLXContextID* = GLXContextID

  GLXBool = cint

proc glXChooseVisual*(dpy: PDisplay, screen: cint, attribList: ptr int32): PXVisualInfo{.
    cdecl, dynlib: dllname, importc: "glXChooseVisual".}
proc glXCreateContext*(dpy: PDisplay, vis: PXVisualInfo, shareList: GLXContext,
                       direct: GLXBool): GLXContext{.cdecl, dynlib: dllname,
    importc: "glXCreateContext".}
proc glXDestroyContext*(dpy: PDisplay, ctx: GLXContext){.cdecl, dynlib: dllname,
    importc: "glXDestroyContext".}
proc glXMakeCurrent*(dpy: PDisplay, drawable: GLXDrawable, ctx: GLXContext): GLXBool{.
    cdecl, dynlib: dllname, importc: "glXMakeCurrent".}
proc glXCopyContext*(dpy: PDisplay, src, dst: GLXContext, mask: int32){.cdecl,
    dynlib: dllname, importc: "glXCopyContext".}
proc glXSwapBuffers*(dpy: PDisplay, drawable: GLXDrawable){.cdecl,
    dynlib: dllname, importc: "glXSwapBuffers".}
proc glXCreateGLXPixmap*(dpy: PDisplay, visual: PXVisualInfo, pixmap: XPixmap): GLXPixmap{.
    cdecl, dynlib: dllname, importc: "glXCreateGLXPixmap".}
proc glXDestroyGLXPixmap*(dpy: PDisplay, pixmap: GLXPixmap){.cdecl,
    dynlib: dllname, importc: "glXDestroyGLXPixmap".}
proc glXQueryExtension*(dpy: PDisplay, errorb, event: var cint): GLXBool{.cdecl,
    dynlib: dllname, importc: "glXQueryExtension".}
proc glXQueryVersion*(dpy: PDisplay, maj, min: var cint): GLXBool{.cdecl,
    dynlib: dllname, importc: "glXQueryVersion".}
proc glXIsDirect*(dpy: PDisplay, ctx: GLXContext): GLXBool{.cdecl, dynlib: dllname,
    importc: "glXIsDirect".}
proc glXGetConfig*(dpy: PDisplay, visual: PXVisualInfo, attrib: cint,
                   value: var cint): cint{.cdecl, dynlib: dllname,
    importc: "glXGetConfig".}
proc glXGetCurrentContext*(): GLXContext{.cdecl, dynlib: dllname,
    importc: "glXGetCurrentContext".}
proc glXGetCurrentDrawable*(): GLXDrawable{.cdecl, dynlib: dllname,
    importc: "glXGetCurrentDrawable".}
proc glXWaitGL*(){.cdecl, dynlib: dllname, importc: "glXWaitGL".}
proc glXWaitX*(){.cdecl, dynlib: dllname, importc: "glXWaitX".}
proc glXUseXFont*(font: XFont, first, count, list: cint){.cdecl, dynlib: dllname,
    importc: "glXUseXFont".}
  # GLX 1.1 and later
proc glXQueryExtensionsString*(dpy: PDisplay, screen: cint): cstring{.cdecl,
    dynlib: dllname, importc: "glXQueryExtensionsString".}
proc glXQueryServerString*(dpy: PDisplay, screen, name: cint): cstring{.cdecl,
    dynlib: dllname, importc: "glXQueryServerString".}
proc glXGetClientString*(dpy: PDisplay, name: cint): cstring{.cdecl,
    dynlib: dllname, importc: "glXGetClientString".}
  # Mesa GLX Extensions
proc glXCreateGLXPixmapMESA*(dpy: PDisplay, visual: PXVisualInfo,
                             pixmap: XPixmap, cmap: XColormap): GLXPixmap{.
    cdecl, dynlib: dllname, importc: "glXCreateGLXPixmapMESA".}
proc glXReleaseBufferMESA*(dpy: PDisplay, d: GLXDrawable): GLXBool{.cdecl,
    dynlib: dllname, importc: "glXReleaseBufferMESA".}
proc glXCopySubBufferMESA*(dpy: PDisplay, drawbale: GLXDrawable,
                           x, y, width, height: cint){.cdecl, dynlib: dllname,
    importc: "glXCopySubBufferMESA".}
proc glXGetVideoSyncSGI*(counter: var int32): cint{.cdecl, dynlib: dllname,
    importc: "glXGetVideoSyncSGI".}
proc glXWaitVideoSyncSGI*(divisor, remainder: cint, count: var int32): cint{.
    cdecl, dynlib: dllname, importc: "glXWaitVideoSyncSGI".}
# implementation
