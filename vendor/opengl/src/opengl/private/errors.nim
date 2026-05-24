import macros, sequtils

proc glGetError*(): GLenum {.stdcall, importc, ogl.}

macro wrapErrorChecking*(f: untyped): typed =
  f.expectKind nnkStmtList
  result = newStmtList()

  for child in f.children:
    if child.kind == nnkCommentStmt:
      continue
    child.expectKind nnkProcDef

    let params = toSeq(child.params.children)
    var glProc = copy child
    glProc.pragma = newTree(nnkPragma,
        newTree(nnkExprColonExpr,
          ident"importc" , newLit($child.name)),
        ident"ogl")

    let rawGLprocName = $glProc.name
    glProc.name = ident(rawGLprocName & "Impl")
    var
      body = newStmtList glProc
      returnsSomething = child.params[0].kind != nnkEmpty
      callParams = newSeq[NimNode]()
    for param in params[1 ..< params.len]:
      callParams.add param[0]

    let glCall = newCall(glProc.name, callParams)
    body.add if returnsSomething:
        newAssignment(ident"result", glCall)
      else:
        glCall

    if rawGLprocName == "glBegin":
      body.add newAssignment(ident"gInsideBeginEnd", ident"true")
    if rawGLprocName == "glEnd":
      body.add newAssignment(ident"gInsideBeginEnd", ident"false")

    template errCheck: untyped =
      when not (NoAutoGLerrorCheck):
        if gAutoGLerrorCheck and not gInsideBeginEnd:
          checkGLerror()

    body.add getAst(errCheck())

    var procc = newProc(child.name, params, body)
    procc.pragma = newTree(nnkPragma, ident"inline")
    procc.name = postfix(procc.name, "*")
    result.add procc

type
  GLerrorCode* {.size: GLenum.sizeof.} = enum
    glErrNoError = (0, "no error")
    glErrInvalidEnum = (0x0500, "invalid enum")
    glErrInvalidValue = (0x0501, "invalid value")
    glErrInvalidOperation = (0x0502, "invalid operation")
    glErrStackOverflow = (0x0503, "stack overflow")
    glErrStackUnderflow = (0x0504, "stack underflow")
    glErrOutOfMem = (0x0505, "out of memory")
    glErrInvalidFramebufferOperation = (0x0506, "invalid framebuffer operation")
    glErrTableTooLarge = (0x8031, "table too large")

const AllErrorCodes = [
    glErrNoError,
    glErrInvalidEnum,
    glErrInvalidValue,
    glErrInvalidOperation,
    glErrStackOverflow,
    glErrStackUnderflow,
    glErrOutOfMem,
    glErrInvalidFramebufferOperation,
    glErrTableTooLarge,
]

proc getGLerrorCode*: GLerrorCode = glGetError().GLerrorCode
  ## Like ``glGetError`` but returns an enumerator instead.

type
  GLerror* = object of Exception
    ## An exception for OpenGL errors.
    code*: GLerrorCode ## The error code. This might be invalid for two reasons:
                    ## an outdated list of errors or a bad driver.

proc checkGLerror* =
  ## Raise ``GLerror`` if the last call to an OpenGL function generated an error.
  ## You might want to call this once every frame for example if automatic
  ## error checking has been disabled.
  let error = getGLerrorCode()
  if error == glErrNoError:
    return

  var
    exc = new(GLerror)
  for e in AllErrorCodes:
    if e == error:
      exc.msg = "OpenGL error: " & $e
      raise exc

  exc.code = error
  exc.msg = "OpenGL error: unknown (" & $error & ")"
  raise exc

{.push warning[User]: off.}

const
  NoAutoGLerrorCheck* = defined(noAutoGLerrorCheck) ##\
  ## This determines (at compile time) whether an exception should be raised
  ## if an OpenGL call generates an error. No additional code will be generated
  ## and ``enableAutoGLerrorCheck(bool)`` will have no effect when
  ## ``noAutoGLerrorCheck`` is defined.

{.pop.} # warning[User]: off

var
  gAutoGLerrorCheck = true
  gInsideBeginEnd* = false # do not change manually.

proc enableAutoGLerrorCheck*(yes: bool) =
  ## This determines (at run time) whether an exception should be raised if an
  ## OpenGL call generates an error. This has no effect when
  ## ``noAutoGLerrorCheck`` is defined.
  gAutoGLerrorCheck = yes
