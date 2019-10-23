import macros, strutils

type Config* = object
  scrollSpeed*: float
  dragVelocityFactor*: float
  dragFriction*: float
  scaleFriction*: float
  scalePanning*: float
  fps*: int
  vertexShader*: string
  fragmentShader*: string

const defaultConfig* = Config(
  scrollSpeed: 1.0,
  dragVelocityFactor: 10.0,
  dragFriction: 1.0,
  scaleFriction: 10.0,
  scalePanning: 0.05,
  fps: 60
)

macro parseObject(obj: typed, key, val: string) =
  result = newNimNode(nnkCaseStmt).add(key)
  for c in obj.getType[2]:
    let a = case c.getType.typeKind
    of ntyFloat:
      newCall("parseFloat", val)
    of ntyInt:
      newCall("parseInt", val)
    of ntyString:
      val
    else:
      error "Unsupported type: " & c.getType.`$`
      val
    result.add newNimNode(nnkOfBranch).add(
      newLit $c,
      newStmtList(quote do: `obj`.`c` = `a`)
    )
  result.add newNimNode(nnkElse).add(quote do:
    raise newException(CatchableError, "Unknown config key " & `key`))

proc loadConfig*(filePath: string): Config =
  result = defaultConfig
  for line in filePath.lines:
    let pair = line.split('=', 1)
    let key = pair[0].strip
    let value = pair[1].strip
    result.parseObject key, value
