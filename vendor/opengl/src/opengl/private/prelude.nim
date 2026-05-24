{.deadCodeElim: on.}
{.push warning[User]: off.}

when defined(windows):
  const
    ogldll* = "OpenGL32.dll"
    gludll* = "GLU32.dll"
elif defined(macosx):
  #macosx has this notion of a framework, thus the path to the openGL dylib files
  #is absolute
  const
    ogldll* = "/System/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries/libGL.dylib"
    gludll* = "/System/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries/libGLU.dylib"
else:
  const
    ogldll* = "libGL.so.1"
    gludll* = "libGLU.so.1"

when defined(useGlew):
  {.pragma: ogl, header: "<GL/glew.h>".}
  {.pragma: oglx, header: "<GL/glxew.h>".}
  {.pragma: wgl, header: "<GL/wglew.h>".}
  {.pragma: glu, dynlib: gludll.}
  
  when defined(linux) or defined(windows):
    {.passC: "-flto -useGlew".}
    when defined(windows):
      {.passL: "-lglew32 -lopengl32".}
    elif defined(linux):
      {.passL: "-lGLEW -lGL".}
elif defined(ios):
  {.pragma: ogl.}
  {.pragma: oglx.}
  {.passC: "-framework OpenGLES", passL: "-framework OpenGLES".}
elif defined(android) or defined(js) or defined(emscripten) or defined(wasm):
  {.pragma: ogl.}
  {.pragma: oglx.}
else:
  # quite complex ... thanks to extension support for various platforms:
  import dynlib

  let oglHandle = loadLib(ogldll)
  if isNil(oglHandle): quit("could not load: " & ogldll)

  when defined(windows):
    var wglGetProcAddress = cast[proc (s: cstring): pointer {.stdcall.}](
      symAddr(oglHandle, "wglGetProcAddress"))
  elif defined(linux):
    var glxGetProcAddress = cast[proc (s: cstring): pointer {.cdecl.}](
      symAddr(oglHandle, "glXGetProcAddress"))
    var glxGetProcAddressArb = cast[proc (s: cstring): pointer {.cdecl.}](
      symAddr(oglHandle, "glXGetProcAddressARB"))

  proc glGetProc(h: LibHandle; procName: cstring): pointer =
    when defined(windows):
      result = symAddr(h, procname)
      if result != nil: return
      if not isNil(wglGetProcAddress): result = wglGetProcAddress(procName)
    elif defined(linux):
      if not isNil(glxGetProcAddress): result = glxGetProcAddress(procName)
      if result != nil: return
      if not isNil(glxGetProcAddressArb):
        result = glxGetProcAddressArb(procName)
        if result != nil: return
      result = symAddr(h, procname)
    else:
      result = symAddr(h, procName)
    if result == nil: raiseInvalidLibrary(procName)

  proc glGetProc*(name: cstring): pointer {.inline.} =
    glGetProc(oglHandle, name)

  var gluHandle: LibHandle

  proc gluGetProc(procname: cstring): pointer =
    if gluHandle == nil:
      gluHandle = loadLib(gludll)
      if gluHandle == nil: quit("could not load: " & gludll)
    result = glGetProc(gluHandle, procname)

  # undocumented 'dynlib' feature: the string literal is replaced by
  # the imported proc name:
  {.pragma: ogl, dynlib: glGetProc("0").}
  {.pragma: oglx, dynlib: glGetProc("0").}
  {.pragma: wgl, dynlib: glGetProc("0").}
  {.pragma: glu, dynlib: gluGetProc("").}

  proc nimLoadProcs0() {.importc.}

  template loadExtensions*() =
    ## call this after your rendering context has been setup if you use
    ## extensions.
    bind nimLoadProcs0
    nimLoadProcs0()

{.pop.} # warning[User]: off
