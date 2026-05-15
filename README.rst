Small immediate mode GUI using SDL3 and Cairo
#############################################

:date: 2026-05-15
:tags: SDL3, cairo, imgui, public domain
:author: Roland Smith <rsmith@xs4all.nl>

.. Last modified: 2026-05-15T14:04:59+0200
.. vim:spelllang=en

Introduction
============

This is a small immediate mode GUI toolkit for SDL3_ and `Cairo graphics`, written in C11.
It was started as a proof of concept and my goal is to keep it simple.
This means;

* It uses Cairo to paint the GUI elements directly, not using a command
  buffer.
* It only supports static positioning, there is no layout engine.
* There are no popups.
* You can add arbitrary cairo drawing commands in the main loop.

.. _SDL3: https://www.libsdl.org/
.. _Cairo graphics: https://www.cairographics.org/

Currently, it has the following UI elements;

* button
* label
* checkbox
* radiobuttons
* colorsample
* slider
* spinner
* editbox

All drawing is done on a Cairo surface that shares its pixels with an SDL
texture.
Cairo is used since I prefer vector graphics and it uses anti-aliasing.
SDL is used for its multiplatform support.

This is free and unencumbered software released into the public domain.


No AI policy
============

This code has been written by a human and is meant for humans.
"AI" / LLM-generated rewrites and additions are not welcome.


Requirements
============

* C compiler supporting C11, tested with ``clang`` and ``gcc``.
* SDL3 library.
* Cairo graphics library.
* BSD or GNU make for building the demos.


Building the demo programs
==========================

A simple ``make`` builds the demo programs.
You will find the executables in the ``build/`` directory.

If you cannot use ``make``, the following example will build the ``cairo-imgui-demo`` on
a UNIX-like system::

    cc `pkg-config --cflags --libs sdl3 cairo` \
    -o ./build/cairo-imgui-demo ./src/cairo-imgui-demo.c ./src/cairo-imgui.c \
    -lm

If ``pkg-config`` is not available on your system, you will have to supply the
locations of the headers and libraries yourself. For example::

    cc -I<header directory> -L<library directory> \
    -o ./build/cairo-imgui-demo ./src/cairo-imgui-demo.c ./src/cairo-imgui.c \
    -lSDL3 -lcairo -lm


Using sdl3-cairo-imgui in your own projects
===========================================

To use the it, simply copy ``src/cairo-imgui.h`` and ``src/cairo-imgui.c``
into your project, and connect them to the build.

License
=======

This code is in the public domain.
