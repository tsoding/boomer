import vec2
import math
import config

type Mouse* = object
  curr*: Vec2
  prev*: Vec2
  drag*: bool

type Camera* = object
  position*: Vec2
  velocity*: Vec2
  scale*: float
  delta_scale*: float

proc world*(camera: Camera, v: Vec2): Vec2 =
  (v - camera.position) / camera.scale

proc screen*(camera: Camera, v: Vec2): Vec2 =
  v * camera.scale + camera.position

proc update*(camera: var Camera, config: Config, dt: float, mouse: Mouse) =
  if abs(camera.delta_scale) > 0.5:
    let wp0 = camera.world(mouse.curr)
    camera.scale = max(camera.scale + camera.delta_scale * dt, 1.0)
    let wp1 = camera.world(mouse.curr)
    let dwp = wp0 - wp1
    camera.position += dwp
    camera.delta_scale -= sgn(camera.delta_scale).float * config.scale_friction * dt

  if not mouse.drag and (camera.velocity.len > 20.0):
    camera.position += camera.velocity * dt
    camera.velocity = camera.velocity - camera.velocity.norm * config.drag_friction * dt
