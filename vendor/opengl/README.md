# opengl
An OpenGL interface

# Extension loading
``loadExtensions()`` must be executed after the creation of a rendering context and before any OpenGL extension procs are used.

# Automatic error checking
The OpenGL procs do perform automatic error checking by default. This can be disabled at compile-time by defining the conditional symbol ``noAutoGLerrorCheck`` (-d:noAutoGLerrorCheck), in which case the error checking code will be omitted from the binary; or at run-time by executing this statement: ``enableAutoGLerrorCheck(false)``.

# Building with x11 (linux)
When receiving the following error:
```
<path-to-opengl>/opengl/private/prelude.nim(5, 10) Error: cannot open file: X
```
Version 1.2.0 is broken for Linux builds, as x11 is imported incorrectly - use 1.2.2 or greater!
