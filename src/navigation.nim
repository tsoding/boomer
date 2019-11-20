import math
import config
import la
import image

const VELOCITY_THRESHOLD = 10.0

type Mouse* = object
  curr*: Vec2f
  prev*: Vec2f
  drag*: bool

type Camera* = object
  position*: Vec2f
  velocity*: Vec2f
  scale*: float32
  deltaScale*: float

proc world*(camera: Camera, v: Vec2f): Vec2f =
  (camera.position + v) / camera.scale

proc update*(camera: var Camera, config: Config, dt: float, mouse: Mouse, image: Image) =
  if abs(camera.deltaScale) > 0.5:
    # TODO(#48): camera position adjustment doesn't work anymore
    camera.scale = max(camera.scale + camera.delta_scale * dt, 0.01)
    camera.delta_scale -= sgn(camera.delta_scale).float * config.scale_friction * dt

  if not mouse.drag and (camera.velocity.length > VELOCITY_THRESHOLD):
    camera.position += camera.velocity * dt
    camera.velocity -= camera.velocity.normalize * (config.dragFriction * dt)
