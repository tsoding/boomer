import math

type Vec2f* = tuple[x: float32, y: float32]
type Mat4f* = array[0 .. 15, float32]

proc vec2*(x: float32, y: float32): Vec2f = (x, y)

proc caddr*(a: var Mat4f): ptr float32 =
  addr a[0]

proc `*`*(a: Vec2f, s: float32): Vec2f =
  (a.x * s, a.y * s)

proc `-`*(a: Vec2f, b: Vec2f): Vec2f =
  (a.x - b.x, a.y - b.y)

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
    return (0.0'f32, 0.0'f32)
  else:
    return (a.x / b, a.y / b)

proc mat4f*(x: float32): Mat4f =
  [x,       0.0'f32, 0.0'f32, 0.0'f32,
   0.0'f32, x,       0.0'f32, 0.0'f32,
   0.0'f32, 0.0'f32, x,       0.0'f32,
   0.0'f32, 0.0'f32, 0.0'f32, x]

proc translate*(mat: Mat4f, x: float32, y: float32, z: float32): Mat4f =
  result = mat
  result[12] += x
  result[13] += y
  result[14] += z

proc scale*(mat: Mat4f, s: float32): Mat4f =
  result = mat
  result[0 * 4 + 0] *= s
  result[1 * 4 + 1] *= s
  result[2 * 4 + 2] *= s
