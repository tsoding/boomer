import macros
import strutils

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

proc loadConfig*(filePath: string): Config =
  result = defaultConfig
  for line in filePath.lines:
    let pair = line.split('=')
    let key = pair[0].strip
    let value = pair[1].strip
    case key
    of "scroll_speed":
      result.scroll_speed = value.parseFloat
    of "drag_velocity_factor":
      result.drag_velocity_factor = value.parseFloat
    of "drag_friction":
      result.drag_friction = value.parseFloat
    of "scale_friction":
      result.scale_friction = value.parseFloat
    of "fps":
      result.fps = value.parseInt
    else:
      raise newException(Exception, "Unknown config key " & key)
