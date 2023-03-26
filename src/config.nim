import strutils

type Config* = object
  min_scale*: float
  scroll_speed*: float
  drag_friction*: float
  scale_friction*: float

const defaultConfig* = Config(
  min_scale: 0.01,
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
    of "min_scale":
      result.min_scale = parseFloat(value)
    of "scroll_speed":
      result.scroll_speed = parseFloat(value)
    of "drag_friction":
      result.drag_friction = parseFloat(value)
    of "scale_friction":
      result.scale_friction = parseFloat(value)
    else:
      quit "Unknown config key `$#`" % [key]

proc generateDefaultConfig*(filePath: string) =
  var f = open(filePath, fmWrite)
  defer: f.close
  f.write("min_scale = ", defaultConfig.min_scale, "\n")
  f.write("scroll_speed = ", defaultConfig.scroll_speed, "\n")
  f.write("drag_friction = ", defaultConfig.drag_friction, "\n")
  f.write("scale_friction = ", defaultConfig.scale_friction, "\n")
