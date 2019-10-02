import vec2
import math

const SCROLL_SPEED* = 1.0
const DRAG_VELOCITY_FACTOR*: float = 20.0
const FRICTION*: float = 2000.0
const SCALE_FRICTION*: float = 5.0

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

proc update*(camera: var Camera, dt: float, mouse: Mouse) =
  if abs(camera.delta_scale) > 0.5:
    let wp0 = camera.world(mouse.curr)
    camera.scale = max(camera.scale + camera.delta_scale * dt, 1.0)
    let wp1 = camera.world(mouse.curr)
    let dwp = wp1 - wp0
    camera.position += dwp
    camera.delta_scale -= sgn(camera.delta_scale).float * SCALE_FRICTION * dt

  if not mouse.drag and (camera.velocity.len > 20.0):
    camera.position += camera.velocity * dt
    camera.velocity = camera.velocity - camera.velocity.norm * FRICTION * dt
