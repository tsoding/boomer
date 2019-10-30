import math
import config
import la
import image

type Mouse* = object
  curr*: Vec2f
  prev*: Vec2f
  drag*: bool

type Camera* = object
  position*: Vec2f
  velocity*: Vec2f
  scale*: float32
  deltaScale*: float

proc world*(point: Vec2f, image: Image, camera: Camera): Vec2f =
  let f = (camera.position + vec2(1.0f32, 1.0f32)) / vec2(2.0f32, 2.0f32)
  let ps = vec2(image.width.float32 * camera.scale, image.height.float32 * camera.scale) * f
  let ms = vec2(point.x.float32, point.y.float32) + ps
  return vec2(ms.x / (image.width.float32 * camera.scale) * 2.0f32 - 1.0f32,
              ms.y / (image.height.float32 * camera.scale) * 2.0f32 - 1.0f32)

proc update*(camera: var Camera, config: Config, dt: float, mouse: Mouse, image: Image) =
  if abs(camera.deltaScale) > 0.5:
    # TODO: camera position adjustment doesn't work anymore
    camera.scale = max(camera.scale + camera.delta_scale * dt, 1.0)
    camera.delta_scale -= sgn(camera.delta_scale).float * config.scale_friction * dt

  if not mouse.drag and (camera.velocity.length > 0.01):
    camera.position += camera.velocity * dt
    camera.velocity -= camera.velocity.normalize * (config.dragFriction * dt)
