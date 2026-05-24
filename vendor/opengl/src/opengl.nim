#
#
#            Nim's Runtime Library
#        (c) Copyright 2012-2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module is a wrapper around `opengl`:idx:. If you define the symbol
## ``useGlew`` this wrapper does not use Nim's ``dynlib`` mechanism,
## but `glew`:idx: instead. However, this shouldn't be necessary anymore; even
## extension loading for the different operating systems is handled here.
##
## You need to call ``loadExtensions`` after a rendering context has been
## created to load any extension proc that your code uses.

include opengl/private/prelude, opengl/private/types,
    opengl/private/errors, opengl/private/procs, opengl/private/constants