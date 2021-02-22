import x11/xlib

import config
import la

const VELOCITY_THRESHOLD = 15.0

type Mouse* = object
  curr*: Vec2f
  prev*: Vec2f
  drag*: bool

type Camera* = object
  position*: Vec2f
  velocity*: Vec2f
  scale*: float32
  deltaScale*: float
  scalePivot*: Vec2f

proc world*(camera: Camera, v: Vec2f): Vec2f =
  v / camera.scale

proc update*(camera: var Camera, config: Config, dt: float, mouse: Mouse, image: PXImage, windowSize: Vec2f) =
  if abs(camera.deltaScale) > 0.5:
    let p0 = (camera.scalePivot - (windowSize * 0.5)) / camera.scale
    camera.scale = max(camera.scale + camera.delta_scale * dt, config.min_scale)
    let p1 = (camera.scalePivot - (windowSize * 0.5)) / camera.scale
    camera.position += p0 - p1

    camera.delta_scale -= camera.delta_scale * dt * config.scale_friction

  if not mouse.drag and (camera.velocity.length > VELOCITY_THRESHOLD):
    camera.position += camera.velocity * dt
    camera.velocity -= camera.velocity * dt * config.dragFriction
