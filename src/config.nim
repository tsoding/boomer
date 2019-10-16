import macros, strutils

type Config* = object
  scrollSpeed*: float
  dragVelocityFactor*: float
  dragFriction*: float
  scaleFriction*: float
  fps*: int

const defaultConfig* = Config(
  scroll_speed: 1.0,
  drag_velocity_factor: 20.0,
  drag_friction: 2000.0,
  scale_friction: 5.0,
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
