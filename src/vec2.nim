import math

type Vec2* = tuple[x: float, y: float]

proc `-`*(v1: Vec2, v2: Vec2): Vec2 {.inline.} = (v1.x - v2.x, v1.y - v2.y)
proc `+`*(v1: Vec2, v2: Vec2): Vec2 {.inline.} = (v1.x + v2.x, v1.y + v2.y)
proc `*`*(v: Vec2, s: float): Vec2 {.inline.} = (v.x * s, v.y * s)
proc `/`*(v: Vec2, s: float): Vec2 {.inline.} = (v.x / s, v.y / s)
proc `+=`*(v1: var Vec2, v2: Vec2) {.inline.} =
  v1.x += v2.x
  v1.y += v2.y
proc `*=`*(v: var Vec2, s: float) {.inline.} =
  v.x *= s
  v.y *= s

proc len*(v: Vec2): float {.inline.} =
  sqrt(v.x * v.x + v.y * v.y)

proc norm*(v: Vec2): Vec2 {.inline.} =
  let l = v.len
  if abs(l) < 1e-9:
    result = (0.0, 0.0)
  else:
    result = (v.x / l, v.y / l)
