import macros, strutils

type Config* = object
  scroll_speed*: float
  drag_friction*: float
  scale_friction*: float

const defaultConfig* = Config(
  scroll_speed: 1.5,
  drag_friction: 6.0,
  scale_friction: 4.0,
)

proc loadConfig*(filePath: string): Config =
  result = defaultConfig
  for rawLine in filePath.lines:
    let line = rawLine.strip
    if line.len == 0 or line[0] == '#':
      continue
    let pair = line.split('=', 1)
    let key = pair[0].strip
    let value = pair[1].strip
    case key
    of "scroll_speed":
      result.scroll_speed = parseFloat(value)
    of "drag_friction":
      result.drag_friction = parseFloat(value)
    of "scale_friction":
      result.scale_friction = parseFloat(value)
    else:
      quit "Unknown config key `$#`" % [key]
