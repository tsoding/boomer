import os

import navigation
import screenshot
import config

import x11/xlib,
       x11/x,
       x11/xutil,
       x11/keysym,
       x11/xrandr,
       x11/cursorfont
import opengl, opengl/glx
import la
import strutils
import math
import options

type Shader = tuple[path, content: string]

proc readShader(file: string): Shader =
  when nimvm:
    result.path = file
    result.content = slurp result.path
  else:
    result.path = "src" / file
    result.content = readFile result.path

when defined(developer):
  var
    vertexShader = readShader "vert.glsl"
    fragmentShader = readShader "frag.glsl"

  proc reloadShader(shader: var Shader) =
    shader.content = readFile shader.path
else:
  const
    vertexShader = readShader "vert.glsl"
    fragmentShader = readShader "frag.glsl"

proc newShader(shader: Shader, kind: GLenum): GLuint =
  result = glCreateShader(kind)
  var shaderArray = allocCStringArray([shader.content])
  glShaderSource(result, 1, shaderArray, nil)
  glCompileShader(result)
  deallocCStringArray(shaderArray)

  var success: GLint
  var infoLog = newString(512).cstring
  glGetShaderiv(result, GL_COMPILE_STATUS, addr success)
  if not success.bool:
    glGetShaderInfoLog(result, 512, nil, infoLog)
    echo "------------------------------"
    echo "Error during shader compilation: ", shader.path, ". Log:"
    echo infoLog
    echo "------------------------------"

proc newShaderProgram(vertex, fragment: Shader): GLuint =
  result = glCreateProgram()

  var
    vertexShader = newShader(vertex, GL_VERTEX_SHADER)
    fragmentShader = newShader(fragment, GL_FRAGMENT_SHADER)

  glAttachShader(result, vertexShader)
  glAttachShader(result, fragmentShader)

  glLinkProgram(result)

  glDeleteShader(vertexShader)
  glDeleteShader(fragmentShader)

  var success: GLint
  var infoLog = newString(512).cstring
  glGetProgramiv(result, GL_LINK_STATUS, addr success)
  if not success.bool:
    glGetProgramInfoLog(result, 512, nil, infoLog)
    echo infoLog

  glUseProgram(result)

type Flashlight = object
  isEnabled: bool
  shadow: float32
  radius: float32
  deltaRadius: float32

const
  INITIAL_FL_DELTA_RADIUS = 250.0
  FL_DELTA_RADIUS_DECELERATION = 10.0

proc update(flashlight: var Flashlight, dt: float32) =
  if abs(flashlight.deltaRadius) > 1.0:
    flashlight.radius = max(0.0, flashlight.radius + flashlight.deltaRadius * dt)
    flashlight.deltaRadius -= flashlight.deltaRadius * FL_DELTA_RADIUS_DECELERATION * dt

  if flashlight.isEnabled:
    flashlight.shadow = min(flashlight.shadow + 6.0 * dt, 0.8)
  else:
    flashlight.shadow = max(flashlight.shadow - 6.0 * dt, 0.0)

proc draw(screenshot: PXImage, camera: Camera, shader, vao, texture: GLuint,
          windowSize: Vec2f, mouse: Mouse, flashlight: Flashlight) =
  glClearColor(0.1, 0.1, 0.1, 1.0)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

  glUseProgram(shader)

  glUniform2f(glGetUniformLocation(shader, "cameraPos".cstring), camera.position[0], camera.position[1])
  glUniform1f(glGetUniformLocation(shader, "cameraScale".cstring), camera.scale)
  glUniform2f(glGetUniformLocation(shader, "screenshotSize".cstring),
              screenshot.width.float32,
              screenshot.height.float32)
  glUniform2f(glGetUniformLocation(shader, "windowSize".cstring),
              windowSize.x.float32,
              windowSize.y.float32)
  glUniform2f(glGetUniformLocation(shader, "cursorPos".cstring),
              mouse.curr.x.float32,
              mouse.curr.y.float32)
  glUniform1f(glGetUniformLocation(shader, "flShadow".cstring), flashlight.shadow)
  glUniform1f(glGetUniformLocation(shader, "flRadius".cstring), flashlight.radius)

  glBindVertexArray(vao)
  glDrawElements(GL_TRIANGLES, count = 6, GL_UNSIGNED_INT, indices = nil)

proc getCursorPosition(display: PDisplay): Vec2f =
  var root, child: Window
  var root_x, root_y, win_x, win_y: cint
  var mask: cuint
  discard XQueryPointer(
    display, DefaultRootWindow(display),
    addr root, addr child,
    addr root_x, addr root_y,
    addr winX, addr winY,
    addr mask);
  result.x = root_x.float32
  result.y = root_y.float32

proc selectWindow(display: PDisplay): Window =
  var cursor = XCreateFontCursor(display, XC_crosshair)
  defer: discard XFreeCursor(display, cursor)

  var root = DefaultRootWindow(display)
  discard XGrabPointer(display, root, 0,
                       ButtonMotionMask or
                       ButtonPressMask or
                       ButtonReleaseMask,
                       GrabModeAsync, GrabModeAsync,
                       root, cursor,
                       CurrentTime)
  defer: discard XUngrabPointer(display, CurrentTime)

  discard XGrabKeyboard(display, root, 0,
                        GrabModeAsync, GrabModeAsync,
                        CurrentTime)
  defer: discard XUngrabKeyboard(display, CurrentTime)

  var event: XEvent
  while true:
    discard XNextEvent(display, addr event)
    case event.theType
    of ButtonPress:
      return event.xbutton.subwindow
    of KeyPress:
      return root
    else:
      discard

  return root

proc xElevenErrorHandler(display: PDisplay, errorEvent: PXErrorEvent): cint{.cdecl.} =
  const CAPACITY = 256
  var errorMessage: array[CAPACITY, char]
  discard XGetErrorText(display, errorEvent.error_code.cint, cast[cstring](addr errorMessage), CAPACITY)
  echo "X ELEVEN ERROR: ", $(cast[cstring](addr errorMessage))

proc main() =
  let boomerDir = getConfigDir() / "boomer"
  var configFile = boomerDir / "config"
  var windowed = false
  var delaySec = 0.0

  # TODO(#95): Make boomer optionally wait for some kind of event (for example, key press)
  block:
    proc versionQuit() =
      const hash = gorgeEx("git rev-parse HEAD")
      quit "boomer-$#" % [if hash.exitCode == 0: hash.output[0 .. 7] else: "unknown"]
    proc usageQuit() =
      quit """Usage: boomer [OPTIONS]
  -d, --delay <seconds: float>  delay execution of the program by provided <seconds>
  -h, --help                    show this help and exit
      --new-config [filepath]   generate a new default config at [filepath]
  -c, --config <filepath>       use config at <filepath>
  -V, --version                 show the current version and exit
  -w, --windowed                windowed mode instead of fullscreen"""
    var i = 1
    while i <= paramCount():
      let arg = paramStr(i)

      template asParam(paramVar: untyped, body: untyped) =
        if i + 1 > paramCount():
          echo "No value is provided for $#" % [arg]
          usageQuit()
        let paramVar = paramStr(i + 1)
        body
        i += 2

      template asFlag(body: untyped) =
        body
        i += 1

      template asOptionalParam(paramVar: untyped, body: untyped) =
        let paramVar = block:
          var resultVal = none(string)
          if i + 1 <= paramCount():
            let param = paramStr(i + 1)
            if len(param) > 0 and param[0] != '-':
              resultVal = some(param)
          resultVal
        body
        if paramVar.isNone:
          i += 1
        else:
          i += 2

      case arg
      of "-d", "--delay":
        asParam(delayParam):
          delaySec = parseFloat(delayParam)
      of "-w", "--windowed":
        asFlag():
          windowed = true
      of "-h", "--help":
        asFlag():
          usageQuit()
      of "-V", "--version":
        asFlag():
          versionQuit()
      of "--new-config":
        asOptionalParam(configName):
          let newConfigPath = configName.get(configFile)

          createDir(newConfigPath.splitFile.dir)
          if newConfigPath.fileExists:
            stdout.write("File ", newConfigPath, " already exists. Replace it? [yn] ")
            if stdin.readChar != 'y':
              quit "Disaster prevented"

          generateDefaultConfig(newConfigPath)
          quit "Generated config at $#" % [newConfigPath]
      of "-c", "--config":
        asParam(configParam):
          configFile = configParam
      else:
        echo "Unknown flag `$#`" % [arg]
        usageQuit()
  sleep(floor(delaySec * 1000).int)

  var config = defaultConfig

  if fileExists configFile:
    config = loadConfig(configFile)
  else:
    stderr.writeLine configFile & " doesn't exist. Using default values. "

  echo "Using config: ", config

  var display = XOpenDisplay(nil)
  if display == nil:
    quit "Failed to open display"
  defer:
    discard XCloseDisplay(display)

  discard XSetErrorHandler(xElevenErrorHandler)

  when defined(select):
    echo "Please select window:"
    var trackingWindow = selectWindow(display)
  else:
    var trackingWindow = DefaultRootWindow(display)

  var screenConfig = XRRGetScreenInfo(display, DefaultRootWindow(display))
  let rate = XRRConfigCurrentRate(screenConfig)
  echo "Screen rate: ", rate

  let screen = XDefaultScreen(display)
  var glxMajor, glxMinor: cint

  if (not glXQueryVersion(display, glxMajor, glxMinor).bool or
      (glxMajor == 1.cint and glxMinor < 3.cint) or
      (glxMajor < 1.cint)):
    quit "Invalid GLX version. Expected >=1.3"
  echo("GLX version ", glxMajor, ".", glxMinor)
  echo("GLX extension: ", glXQueryExtensionsString(display, screen))

  var attrs = [
    GLX_RGBA,
    GLX_DEPTH_SIZE, 24,
    GLX_DOUBLEBUFFER,
    None
  ]

  var vi = glXChooseVisual(display, 0, addr attrs[0])
  if vi == nil:
    quit "No appropriate visual found"


  echo "Visual ", vi.visualid, " selected"
  var swa: XSetWindowAttributes
  swa.colormap = XCreateColormap(display, DefaultRootWindow(display),
                                 vi.visual, AllocNone)
  swa.event_mask = ButtonPressMask or ButtonReleaseMask or
                   KeyPressMask or KeyReleaseMask or
                   PointerMotionMask or ExposureMask or ClientMessage
  if not windowed:
    swa.override_redirect = 1
    swa.save_under = 1

  var attributes: XWindowAttributes
  discard XGetWindowAttributes(
    display,
    DefaultRootWindow(display),
    addr attributes)
  var win = XCreateWindow(
    display, DefaultRootWindow(display),
    0, 0, attributes.width.cuint, attributes.height.cuint, 0,
    vi.depth, InputOutput, vi.visual,
    CWColormap or CWEventMask or CWOverrideRedirect or CWSaveUnder, addr swa)

  discard XMapWindow(display, win)

  var wmName = "boomer"
  var wmClass = "Boomer"
  var hints = XClassHint(res_name: wmName, res_class: wmClass)

  discard XStoreName(display, win, wmName)
  discard XSetClassHint(display, win, addr(hints))

  var wmDeleteMessage = XInternAtom(
    display, "WM_DELETE_WINDOW",
    0.cint)

  discard XSetWMProtocols(display, win,
                          addr wmDeleteMessage, 1)

  var glc = glXCreateContext(display, vi, nil, GL_TRUE.cint)
  discard glXMakeCurrent(display, win, glc)

  loadExtensions()

  var shaderProgram = newShaderProgram(vertexShader, fragmentShader)

  var screenshot = newScreenshot(display, trackingWindow)
  defer: screenshot.destroy(display)

  let w = screenshot.image.width.float32
  let h = screenshot.image.height.float32
  var
    vao, vbo, ebo: GLuint
    vertices = [
      # Position                 Texture coords
      [GLfloat    w,     0, 0.0, 1.0, 1.0], # Top right
      [GLfloat    w,     h, 0.0, 1.0, 0.0], # Bottom right
      [GLfloat    0,     h, 0.0, 0.0, 0.0], # Bottom left
      [GLfloat    0,     0, 0.0, 0.0, 1.0]  # Top left
    ]
    indices = [GLuint(0), 1, 3,
                      1,  2, 3]

  glGenVertexArrays(1, addr vao)
  glGenBuffers(1, addr vbo)
  glGenBuffers(1, addr ebo)
  defer:
    glDeleteVertexArrays(1, addr vao)
    glDeleteBuffers(1, addr vbo)
    glDeleteBuffers(1, addr ebo)

  glBindVertexArray(vao)

  glBindBuffer(GL_ARRAY_BUFFER, vbo)
  glBufferData(GL_ARRAY_BUFFER, size = GLsizeiptr(sizeof(vertices)),
               addr vertices, GL_STATIC_DRAW)

  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, size = GLsizeiptr(sizeof(indices)),
               addr indices, GL_STATIC_DRAW);

  var stride = GLsizei(vertices[0].len * sizeof(GLfloat))

  glVertexAttribPointer(0, 3, cGL_FLOAT, false, stride, cast[pointer](0))
  glEnableVertexAttribArray(0)

  glVertexAttribPointer(1, 2, cGL_FLOAT, false, stride, cast[pointer](3 * sizeof(GLfloat)))
  glEnableVertexAttribArray(1)

  var texture = 0.GLuint
  glGenTextures(1, addr texture)
  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, texture)

  glTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGB.GLint,
               screenshot.image.width,
               screenshot.image.height,
               0,
               # TODO(#13): the texture format is hardcoded
               GL_BGRA,
               GL_UNSIGNED_BYTE,
               screenshot.image.data)
  glGenerateMipmap(GL_TEXTURE_2D)

  glUniform1i(glGetUniformLocation(shaderProgram, "tex".cstring), 0)

  glEnable(GL_TEXTURE_2D)

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER)

  var
    quitting = false
    camera = Camera(scale: 1.0)
    mouse: Mouse =
      block:
        let pos = getCursorPosition(display)
        Mouse(curr: pos, prev: pos)
    flashlight = Flashlight(
      isEnabled: false,
      radius: 200.0)


  let dt = 1.0 / rate.float
  var originWindow: Window
  var revertToReturn: cint
  discard XGetInputFocus(display, addr originWindow, addr revertToReturn)
  while not quitting:
    # TODO(#78): Is there a better solution to keep the focus always on the window?
    if not windowed:
      discard XSetInputFocus(display, win, RevertToParent, CurrentTime);

    var wa: XWindowAttributes
    discard XGetWindowAttributes(display, win, addr wa)
    glViewport(0, 0, wa.width, wa.height)

    var xev: XEvent
    while XPending(display) > 0:
      discard XNextEvent(display, addr xev)

      proc scrollUp() =
        if (xev.xkey.state and ControlMask) > 0.uint32 and flashlight.isEnabled:
          flashlight.deltaRadius += INITIAL_FL_DELTA_RADIUS
        else:
          camera.deltaScale += config.scrollSpeed
          camera.scalePivot = mouse.curr

      proc scrollDown() =
        if (xev.xkey.state and ControlMask) > 0.uint32 and flashlight.isEnabled:
          flashlight.deltaRadius -= INITIAL_FL_DELTA_RADIUS
        else:
          camera.deltaScale -= config.scrollSpeed
          camera.scalePivot = mouse.curr

      case xev.theType
      of Expose:
        discard

      of MotionNotify:
        mouse.curr = vec2(xev.xmotion.x.float32,
                          xev.xmotion.y.float32)

        if mouse.drag:
          let delta = world(camera, mouse.prev) - world(camera, mouse.curr)
          camera.position += delta
          # delta is the distance the mouse traveled in a single
          # frame. To turn the velocity into units/second we need to
          # multiple it by FPS.
          camera.velocity = delta * rate.float

        mouse.prev = mouse.curr

      of ClientMessage:
        if cast[Atom](xev.xclient.data.l[0]) == wmDeleteMessage:
          quitting = true

      of KeyPress:
        var key = XLookupKeysym(cast[PXKeyEvent](xev.addr), 0)
        case key
        of XK_EQUAL: scrollUp()
        of XK_MINUS: scrollDown()
        of XK_0:
          camera.scale = 1.0
          camera.deltaScale = 0.0
          camera.position = vec2(0.0'f32, 0.0)
          camera.velocity = vec2(0.0'f32, 0.0)
        of XK_q, XK_Escape:
          quitting = true
        of XK_r:
          if configFile.len > 0 and fileExists(configFile):
            config = loadConfig(configFile)

          when defined(developer):
            if (xev.xkey.state and ControlMask) > 0.uint32:
              echo "------------------------------"
              echo "RELOADING SHADERS"
              try:
                reloadShader(vertexShader)
                reloadShader(fragmentShader)
                let newShaderProgram = newShaderProgram(vertexShader, fragmentShader)
                glDeleteProgram(shaderProgram)
                shaderProgram = newShaderProgram
                echo "Shader program ID: ", shaderProgram
              except GLerror:
                echo "Could not reload the shaders"
              echo "------------------------------"

        of XK_f:
          flashlight.isEnabled = not flashlight.isEnabled
        else:
          discard

      of ButtonPress:
        case xev.xbutton.button
        of Button1:
          mouse.prev = mouse.curr
          mouse.drag = true
          camera.velocity = vec2(0.0, 0.0)
        of Button4: scrollUp()
        of Button5: scrollDown()
        else:
          discard

      of ButtonRelease:
        case xev.xbutton.button
        of Button1:
          mouse.drag = false
        else:
          discard
      else:
        discard

    camera.update(config, dt, mouse, screenshot.image,
                  vec2(wa.width.float32, wa.height.float32))
    flashlight.update(dt)

    screenshot.image.draw(camera, shaderProgram, vao, texture,
                          vec2(wa.width.float32, wa.height.float32),
                          mouse, flashlight)

    glXSwapBuffers(display, win)
    glFinish()

    when defined(live):
      screenshot.refresh(display, trackingWindow)
      # TODO(#90): don't update the vbo on screenshot refresh
      # I'm pretty sure we can avoid that if we make independent from
      # the size of the window as it was in the beginning. (I simply did
      # not expect this use case back then Kappa)
      var
        w = screenshot.image.width.float32
        h = screenshot.image.height.float32
        vertices = [
          # Position                 Texture coords
          [GLfloat    w,     0, 0.0, 1.0, 1.0], # Top right
          [GLfloat    w,     h, 0.0, 1.0, 0.0], # Bottom right
          [GLfloat    0,     h, 0.0, 0.0, 0.0], # Bottom left
          [GLfloat    0,     0, 0.0, 0.0, 1.0]  # Top left
        ]
        indices = [GLuint(0), 1, 3,
                   1,  2, 3]
      glBindBuffer(GL_ARRAY_BUFFER, vbo)
      glBufferData(GL_ARRAY_BUFFER, size = GLsizeiptr(sizeof(vertices)),
                   addr vertices, GL_STATIC_DRAW)
      glTexImage2D(GL_TEXTURE_2D,
                   0,
                   GL_RGB.GLint,
                   screenshot.image.width,
                   screenshot.image.height,
                   0,
                   # TODO(#13): the texture format is hardcoded
                   GL_BGRA,
                   GL_UNSIGNED_BYTE,
                   screenshot.image.data)
  discard XSetInputFocus(display, originWindow, RevertToParent, CurrentTime);
  discard XSync(display, 0)

main()
