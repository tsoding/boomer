import os

import navigation
import screenshot
import config

import x11/xlib, x11/x, x11/xutil, x11/keysym, x11/xrandr, x11/xshm
import opengl, opengl/glx
import la

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

proc main() =
  var config = defaultConfig
  let
    boomerDir = getConfigDir() / "boomer"
    configFile = boomerDir / "config"

  if existsFile configFile:
    config = loadConfig(configFile)
  else:
    stderr.writeLine configFile & " doesn't exist. Using default values. "

  echo "Using config: ", config

  var display = XOpenDisplay(nil)
  if display == nil:
    quit "Failed to open display"
  defer:
    discard XCloseDisplay(display)

  var root = DefaultRootWindow(display)

  var screenConfig = XRRGetScreenInfo(display, root)
  let rate = XRRConfigCurrentRate(screenConfig)
  echo "Screen rate: ", rate

  let screen = XDefaultScreen(display)
  var glxMajor, glxMinor: int

  if (not glXQueryVersion(display, glxMajor, glxMinor) or
      (glxMajor == 1 and glxMinor < 3) or
      (glxMajor < 1)):
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
  var swa: TXSetWindowAttributes
  swa.colormap = XCreateColormap(display, root,
                                 vi.visual, AllocNone)
  swa.event_mask = ButtonPressMask or ButtonReleaseMask or KeyPressMask or
                   PointerMotionMask or ExposureMask or ClientMessage

  var attributes: TXWindowAttributes
  discard XGetWindowAttributes(
    display,
    DefaultRootWindow(display),
    addr attributes)

  var win = XCreateWindow(
    display, root,
    0, 0, attributes.width.cuint, attributes.height.cuint, 0,
    vi.depth, InputOutput, vi.visual,
    CWColormap or CWEventMask, addr swa)

  discard XMapWindow(display, win)

  var wmName = "boomer"
  var wmClass = "Boomer"
  var hints = TXClassHint(res_name: wmName, res_class: wmClass)

  discard XStoreName(display, win, wmName)
  discard XSetClassHint(display, win, addr(hints))

  var wmDeleteMessage = XInternAtom(
    display, "WM_DELETE_WINDOW",
    false.TBool)

  discard XSetWMProtocols(display, win,
                          addr wmDeleteMessage, 1)

  var glc = glXCreateContext(display, vi, nil, GL_TRUE)
  discard glXMakeCurrent(display, win, glc)

  loadExtensions()

  var shaderProgram = newShaderProgram(vertexShader, fragmentShader)

  var screenshot = newScreenshot(display)
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
    mouse: Mouse
    flashlight = Flashlight(
      isEnabled: false,
      radius: 200.0)

  let dt = 1.0 / rate.float
  while not quitting:
    var wa: TXWindowAttributes
    discard XGetWindowAttributes(display, win, addr wa)
    glViewport(0, 0, wa.width, wa.height)

    var xev: TXEvent
    while XPending(display) > 0:
      discard XNextEvent(display, addr xev)
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
        if cast[TAtom](xev.xclient.data.l[0]) == wmDeleteMessage:
          quitting = true

      of KeyPress:
        var key = XLookupKeysym(cast[PXKeyEvent](xev.addr), 0)
        case key
        of XK_0:
          camera.scale = 1.0
          camera.deltaScale = 0.0
          camera.position = vec2(0.0'f32, 0.0)
          camera.velocity = vec2(0.0'f32, 0.0)
        of XK_q, XK_Escape:
          quitting = true
        of XK_r:
          if configFile.len > 0 and existsFile(configFile):
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

        of Button4:             # Scroll up
          if (xev.xkey.state and ControlMask) > 0.uint32 and flashlight.isEnabled:
            flashlight.deltaRadius += INITIAL_FL_DELTA_RADIUS
          else:
            camera.deltaScale += config.scrollSpeed
            camera.scalePivot = mouse.curr

        of Button5:             # Scoll down
          if (xev.xkey.state and ControlMask) > 0.uint32 and flashlight.isEnabled:
            flashlight.deltaRadius -= INITIAL_FL_DELTA_RADIUS
          else:
            camera.deltaScale -= config.scrollSpeed
            camera.scalePivot = mouse.curr

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
      screenshot.refresh(display)
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
  discard XSync(display, 0)

main()
