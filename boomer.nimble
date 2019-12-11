version     = "0.0.1"
author      = "me"
description = "Zoomer application for boomers"
license     = "MIT"
srcDir      = "src"
bin         = @["boomer"]

requires "nim >= 0.18.0", "x11 >= 1.1", "opengl >= 1.2.3", "syscall#09c647b0c5798e8d3348f0ed90dbb5704d5e8159"
