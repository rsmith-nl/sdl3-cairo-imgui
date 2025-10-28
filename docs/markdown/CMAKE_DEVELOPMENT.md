# CMake Development Setup for cairo-imgui-demo

## Overview

This project has been set up with CMake for modern C development, providing:
- Debug builds with full symbols and warnings
- Release builds with optimizations
- Integrated VS Code debugging
- Code formatting and static analysis

## Prerequisites

Ensure you have MSYS2 with MinGW-w64 installed:
- CMake (available at `/c/msys64/mingw64/bin/cmake.exe`)
- GCC compiler (available at `/c/msys64/mingw64/bin/gcc.exe`)
- SDL3 and Cairo development libraries
- pkg-config for dependency management

## Building

### Using VS Code Tasks

1. **Configure Debug Build**: Press `Ctrl+Shift+P` → "Tasks: Run Task" → "CMake: Configure Debug"
2. **Build Debug**: Press `Ctrl+Shift+P` → "Tasks: Run Task" → "CMake: Build Debug" (or `Ctrl+Shift+B`)
3. **Configure Release Build**: Press `Ctrl+Shift+P` → "Tasks: Run Task" → "CMake: Configure Release"
4. **Build Release**: Press `Ctrl+Shift+P` → "Tasks: Run Task" → "CMake: Build Release"

### Using Terminal

```bash
# Configure for debug build
export PATH="/c/msys64/mingw64/bin:$PATH"
cmake -B build -DCMAKE_BUILD_TYPE=Debug -G "MinGW Makefiles"

# Build the project
cmake --build build --config Debug

# Run the application
./build/bin/cairo-imgui-demo.exe
```

### Using CMake Extension

With the CMake Tools extension installed:
1. Open the Command Palette (`Ctrl+Shift+P`)
2. Run "CMake: Configure"
3. Run "CMake: Build"

## Debugging

### VS Code Debugging

1. Set breakpoints in your C code by clicking in the left margin
2. Press `F5` or go to Run and Debug → "Debug C Application (CMake)"
3. The debugger will:
   - Automatically build the project in debug mode
   - Launch the application with GDB
   - Stop at breakpoints and allow inspection

### Debug Configuration

Two debug configurations are available:
- **Debug C Application (CMake)**: For GDB debugging
- **Debug C Application (MSVC)**: For Visual Studio debugger (if available)

## Build Outputs

- **Debug builds**: `build/bin/cairo-imgui-demo.exe` (with debug symbols)
- **Release builds**: `build/bin/cairo-imgui-demo.exe` (optimized)
- **Build files**: `build/` directory (CMake cache, makefiles, etc.)

## Additional Features

### Code Formatting
```bash
cmake --build build --target style
```
Uses `astyle` to format C source code.

### Static Analysis
```bash
cmake --build build --target tidy
```
Runs `clang-tidy` for static code analysis.

### Running the Application
```bash
cmake --build build --target run
```
Builds and runs the application in one command.

## Project Structure

```
├── CMakeLists.txt          # Main CMake configuration
├── cairo-imgui-demo.c      # Main application source
├── cairo-imgui.c           # GUI implementation
├── cairo-imgui.h           # GUI header
├── build/                  # Build directory (generated)
│   ├── bin/               # Executable output
│   └── ...               # CMake build files
├── .vscode/               # VS Code configuration
│   ├── launch.json        # Debug configurations
│   ├── tasks.json         # Build tasks
│   ├── settings.json      # Workspace settings
│   └── c_cpp_properties.json # IntelliSense configuration
└── cairo-ui--exe-distribution/ # Required DLLs
```

## Dependencies

The project requires:
- SDL3 (found via pkg-config)
- Cairo (found via pkg-config)
- Math library (-lm)

All dependencies are automatically detected and linked by CMake.

## Troubleshooting

### Missing DLLs
If the executable fails to start due to missing DLLs, copy the required libraries:
```bash
cp cairo-ui--exe-distribution/*.dll build/bin/
```

### CMake Not Found
Ensure MSYS2 MinGW64 is in your PATH:
```bash
export PATH="/c/msys64/mingw64/bin:$PATH"
```

### Build Errors
- Check that all dependencies (SDL3, Cairo) are installed in MSYS2
- Verify the compiler and CMake versions
- Clean and reconfigure: `cmake --build build --target clean`

## Comparison with Original Makefile

The CMake setup provides several advantages over the original Makefile:
- Automatic dependency detection
- Cross-platform compatibility
- VS Code integration
- Separate debug/release configurations
- Better dependency management
- Integrated tooling support

To use the original Makefile instead:
```bash
make  # Build with original Makefile
```