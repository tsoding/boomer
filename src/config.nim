import macros, strutils

type Config* = object
  scrollSpeed*: float
  dragVelocityFactor*: float
  dragFriction*: float
  scaleFriction*: float
  fps*: int

const defaultConfig* = Config(
  scrollSpeed: 1.0,
  dragVelocityFactor: 10.0,
  dragFriction: 1.0,
  scaleFriction: 10.0,
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
  for rawLine in filePath.lines:
    let line = rawLine.strip
    if line.len > 0 and line[0] == '#':
      continue
    let pair = line.split('=', 1)
    let key = pair[0].strip
    let value = pair[1].strip
    result.parseObject key, value
