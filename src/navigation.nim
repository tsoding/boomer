import math
import config
import la

type Mouse* = object
  curr*: Vec2f
  prev*: Vec2f
  drag*: bool

type Camera* = object
  position*: Vec2f
  velocity*: Vec2f
  scale*: float
  deltaScale*: float
  matrix*: Mat4f

proc update*(camera: var Camera, config: Config, dt: float, mouse: Mouse) =
  if abs(camera.deltaScale) > 0.5:
    camera.scale = max(camera.scale + camera.deltaScale * dt, 1.0)
    if camera.scale > 1.0:
      camera.position += mouse.curr * (camera.deltaScale / camera.scale * config.scalePanning)
    camera.deltaScale -= sgn(camera.deltaScale).float * config.scaleFriction * dt

  if not mouse.drag and (camera.velocity.length > 0.01):
    camera.position += camera.velocity * dt
    camera.velocity -= camera.velocity.normalize * (config.dragFriction * dt)

  camera.matrix = mat4f(1).translate(-camera.position.x, camera.position.y, 0).scale(camera.scale)
