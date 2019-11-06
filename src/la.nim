import math

type Vec2f* = tuple[x: float32, y: float32]

proc vec2*(x: float32, y: float32): Vec2f = (x, y)

proc `*`*(a: Vec2f, s: float32): Vec2f =
  vec2(a.x * s, a.y * s)

proc `/`*(a: Vec2f, s: float32): Vec2f =
  vec2(a.x / s, a.y / s)

proc `*`*(a: Vec2f, b: Vec2f): Vec2f =
  vec2(a.x * b.x, a.y * b.y)

proc `/`*(a: Vec2f, b: Vec2f): Vec2f =
  vec2(a.x / b.x, a.y / b.y)

proc `-`*(a: Vec2f, b: Vec2f): Vec2f =
  vec2(a.x - b.x, a.y - b.y)

proc `+`*(a: Vec2f, b: Vec2f): Vec2f =
  vec2(a.x + b.x, a.y + b.y)

proc `+=`*(a: var Vec2f, b: Vec2f) =
  a.x += b.x
  a.y += b.y

proc `-=`*(a: var Vec2f, b: Vec2f) =
  a.x -= b.x
  a.y -= b.y

proc length*(a: Vec2f): float32 =
  sqrt(a.x * a.x + a.y * a.y)

proc normalize*(a: Vec2f): Vec2f =
  let b = a.length
  if b == 0.0'f32:
    return vec2(0.0'f32, 0.0'f32)
  else:
    return vec2(a.x / b, a.y / b)
