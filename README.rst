Small immediate mode GUI using SDL3 and Cairo
#############################################

:date: 2025-08-27 00:13:28
:tags: SDL3, cairo
:author: Roland Smith <rsmith@xs4all.nl>

.. Last modified: 2025-08-27T15:50:35+0200
.. vim:spelllang=en

Introduction
============

This is a small immediate mode GUI toolkit for SDL3_ and `Cairo graphics`, written in C11.
It was started as a proof of concept and my goal is to keep it simple.
This means;

* It uses Cairo to paint the GUI elements directly, not using a command
  buffer.
* It only supports static positioning, there is no layout engine.
* It does not support keyboard focus.

.. _SDL3: https://www.libsdl.org/
.. _Cairo graphics: https://www.cairographics.org/


All drawing is done on a Cairo surface that shares its pixels with an SDL
texture.
Cairo is used because of the much richer array of drawing primitives it
supports and it uses anti-aliasing.

This is free and unencumbered software released into the public domain.


Files
=====

* ``cairo-imgui.h``, the header that declares functions and defines structures.
* ``cairo-imgui.c``, the source file that defines the functions.
* ``cairo-imgui-demo.c`` the source for the demo application.

The file ``compile_flags.txt`` exists for clang-based tooling like
``clang-check``.


Requirements
============

* C compiler supporting C11. Development is done using ``clang``.
* SDL3 library.
* Cairo graphics library.

Building with CMake
===================

This project provides a cross‑platform CMake build using **Ninja** that works on Debian 12 GNU/Linux and MSYS2/MinGW (Windows 11).

**Recommended**: Use the included CMake presets for consistent builds across platforms.

Linux (Debian 12)
-----------------

Install dependencies::

  sudo apt install cmake build-essential ninja-build libsdl3-dev libcairo2-dev pkg-config

Configure and build using presets::

  cmake --preset linux-debug
  cmake --build --preset linux-debug

Or for release builds::

  cmake --preset linux-release
  cmake --build --preset linux-release

Run the demo (from project root for asset paths)::

  ./out/build/linux-debug/bin/cairo-imgui-demo

Or using the custom target::

  cmake --build --preset linux-debug --target run

Windows 11 (MSYS2/MinGW)
------------------------

Use the MSYS2 **MINGW64** shell and install packages::

  pacman -S --needed mingw-w64-x86_64-cmake \
                   mingw-w64-x86_64-toolchain \
                   mingw-w64-x86_64-ninja \
                   mingw-w64-x86_64-SDL3 \
                   mingw-w64-x86_64-cairo \
                   pkgconf

Configure and build using presets (in the same shell)::

  cmake --preset windows-debug
  cmake --build --preset windows-debug

Or for release builds::

  cmake --preset windows-release
  cmake --build --preset windows-release

Run the demo (from project root for asset paths)::

  ./out/build/windows-debug/bin/cairo-imgui-demo.exe

Or using the custom target::

  cmake --build --preset windows-debug --target run

Alternative: Manual CMake invocation
-------------------------------------

If you prefer not to use presets, you can invoke CMake manually::

  # Linux
  cmake -G Ninja -S . -B build -DCMAKE_BUILD_TYPE=Debug
  cmake --build build -j

  # Windows (MSYS2 MINGW64 shell)
  cmake -G Ninja -S . -B build -DCMAKE_BUILD_TYPE=Debug -DWINDOWS_GUI_SUBSYSTEM=ON
  cmake --build build -j

Notes
-----

* **Asset paths**: Always run the demo from the project root directory. The build outputs to ``out/build/{preset}/bin/`` but relative asset paths (like ``assets/image.bmp``) are resolved from the working directory. Both the CMake ``run`` target and VS Code debug configurations automatically set the working directory to the project root for uniform path behavior across debug and release builds.
* **Testing asset paths**: To verify that asset loading works correctly, build and run the test program: ``cmake --build --preset linux-debug --target test-assets`` (or ``windows-debug`` on Windows). This test loads an image from ``assets/test-image.png`` and displays it, confirming the working directory is properly set.
* CMake tries to locate SDL3 and Cairo via their official CMake packages when available, and falls back to ``pkg-config`` otherwise. This works out-of-the-box on both Debian and MSYS2.
* To build the engine as a static library without the demo, configure with ``-DBUILD_DEMO=OFF``.
* On Windows you can request a GUI‑subsystem demo (no console window) with ``-DWINDOWS_GUI_SUBSYSTEM=ON``.


Building the demo
=================

A ``Makefile`` that has been tested with BSD make and GNU make is provided.
The ``CFLAGS`` in the ``Makefile`` are geared towards ``clang``.
You will probably need to adapt them when using ``gcc``.

If you cannot use ``make``, the following command will build the demo on
a UNIX-like system::

    cc `pkg-config --cflags --libs sdl3 cairo` \
    -o cairo-imgui-demo cairo-imgui-demo.c cairo-imgui.c

If ``pkg-config`` is not available on your system, you will have to supply the
locations of the headers and libraries yourself. For example::

    cc -I<header directory> -L<library directory> -lSDL3 -lcairo -lm \
    -o cairo-imgui-demo cairo-imgui-demo.c cairo-imgui.c
