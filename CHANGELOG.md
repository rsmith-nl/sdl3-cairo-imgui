# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2025-10-26

### Fixed
- **Build system compatibility**: Fixed Makefile for GNU make compatibility
  - Changed BSD make syntax (`!=`) to GNU make syntax (`$(shell ...)`) for pkg-config commands
  - Corrected library linking order - moved `$(LFLAGS)` and `$(LIBS)` after source files

- **Math constants**: Fixed M_PI undefined error in cairo-imgui.c
  - Added `#define _GNU_SOURCE` before includes to enable math constants on Linux

### Added
- First successful build on Debian GNU/Linux system
- Verified executable generation: `cairo-imgui-demo` (33,872 bytes)

### Technical Details
- **Environment**: Debian GNU/Linux with GNU Make 4.3
- **Dependencies**: SDL3, Cairo graphics library, libmath
- **Compiler**: GCC with C11 standard
- **Build flags**: Optimized build (-Os) with fast math and native architecture targeting

### Notes
This represents the first working build of this Cairo ImGui demo fork on a Debian system, resolving cross-platform compatibility issues between BSD and GNU build tools.