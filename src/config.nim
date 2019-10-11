import macros

type Config* = object
  scrollSpeed: float
  dragVelocityFactor: float
  dragFriction: float
  scaleFriction: float

macro saveConfig*(config: typed, filePath: typed): untyped =
  if config.getType.typeKind != ntyObject:
    error("Expected object kind", config)

  result = nnkStmtList.newTree(
    nnkVarSection.newTree(
      nnkIdentDefs.newTree(
        newIdentNode("f"),
        newEmptyNode(),
        nnkCall.newTree(
          newIdentNode("open"),
          newLit("hello.conf"),
          newIdentNode("fmWrite")
        )
      )
    ),
    nnkLetSection.newTree(
      nnkIdentDefs.newTree(
        newIdentNode("config"),
        newEmptyNode(),
        config
      )
  ))

  for i in config.getType[2].children:
    result.add(nnkCall.newTree(
      nnkDotExpr.newTree(
        newIdentNode("f"),
        newIdentNode("writeLine")
      ),
      newLit(i.repr),
      newLit("="),
      nnkDotExpr.newTree(
        newIdentNode("config"),
        newIdentNode(i.repr)
      )
    ))

# proc saveConfig(config: Config, filePath: string) =
#   var f = open(filePath, fmWrite)
#   defer: f.close
#   f.writeLine("scroll_speed=", config.scrollSpeed)
#   f.writeLine("drag_velocity_factor=", config.drag_velocity_factor)
#   f.writeLine("drag_friction=", config.drag_friction)
#   f.writeLine("scale_friction=", config.scale_friction)

proc loadConfig(filePath: string): Config =
  discard
