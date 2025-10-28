cmake_minimum_required(VERSION 3.20)

# Project configuration
project(
  cairo-imgui
  VERSION 1.0.0
  LANGUAGES C)

# Set C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Enable debug symbols by default
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE
      Debug
      CACHE STRING "Build type" FORCE)
endif()

# Compiler-specific options
if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
  # Debug flags
  set(CMAKE_C_FLAGS_DEBUG
      "-g3 -O0 -Wall -Wextra -Wstrict-prototypes -Wpedantic -Wshadow -Wmissing-field-initializers -Wpointer-arith"
  )

  # Release flags
  set(CMAKE_C_FLAGS_RELEASE "-Os -ffast-math -march=native -DNDEBUG")

  # Enable AddressSanitizer and UBSan for debug builds (if available)
  if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    option(ENABLE_SANITIZERS "Enable AddressSanitizer and UBSan" OFF)
    if(ENABLE_SANITIZERS)
      set(CMAKE_C_FLAGS_DEBUG
          "${CMAKE_C_FLAGS_DEBUG} -fsanitize=address,undefined")
      set(CMAKE_EXE_LINKER_FLAGS_DEBUG
          "${CMAKE_EXE_LINKER_FLAGS_DEBUG} -fsanitize=address,undefined")
    endif()
  endif()
elseif(MSVC)
  # MSVC debug flags
  set(CMAKE_C_FLAGS_DEBUG "/Od /Zi /W4")
  set(CMAKE_C_FLAGS_RELEASE "/O2 /DNDEBUG")
endif()

# Options
option(BUILD_DEMO "Build the demo executable" ON)
option(WINDOWS_GUI_SUBSYSTEM
       "Build demo as a GUI subsystem app on Windows (no console)" OFF)

# Dependency discovery
include(CheckSymbolExists)

# First try official CMake packages (when available)
set(SDL3_TARGET "")
find_package(SDL3 QUIET CONFIG)
if(SDL3_FOUND AND TARGET SDL3::SDL3)
  set(SDL3_TARGET SDL3::SDL3)
  message(STATUS "Found SDL3 via CMake package: using SDL3::SDL3")
endif()

# Cairo is usually found via pkg-config, but try CMake config first
set(CAIRO_TARGET "")
find_package(Cairo QUIET)
if(TARGET Cairo::Cairo)
  set(CAIRO_TARGET Cairo::Cairo)
  message(STATUS "Found Cairo via CMake package: using Cairo::Cairo")
endif()

# Fallback to pkg-config for anything missing
if(NOT SDL3_TARGET OR NOT CAIRO_TARGET)
  find_package(PkgConfig REQUIRED)
  if(NOT SDL3_TARGET)
    pkg_check_modules(SDL3 REQUIRED IMPORTED_TARGET sdl3)
    set(SDL3_TARGET PkgConfig::SDL3)
    message(STATUS "Found SDL3 via pkg-config: using PkgConfig::SDL3")
  endif()
  if(NOT CAIRO_TARGET)
    pkg_check_modules(CAIRO REQUIRED IMPORTED_TARGET cairo)
    set(CAIRO_TARGET PkgConfig::CAIRO)
    message(STATUS "Found Cairo via pkg-config: using PkgConfig::CAIRO")
  endif()
endif()

# Library target (engine)
add_library(cairo_imgui STATIC cairo-imgui.c)
target_include_directories(cairo_imgui PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(cairo_imgui PUBLIC ${SDL3_TARGET} ${CAIRO_TARGET})
set_target_properties(cairo_imgui PROPERTIES OUTPUT_NAME cairo-imgui)

# Only link libm on non-Windows systems
if(NOT WIN32)
  target_link_libraries(cairo_imgui PUBLIC m)
endif()

# Demo executable
if(BUILD_DEMO)
  set(_DEMO_SOURCES cairo-imgui-demo.c)
  set(_DEMO_NAME cairo-imgui-demo)
  if(WIN32 AND WINDOWS_GUI_SUBSYSTEM)
    add_executable(${_DEMO_NAME} WIN32 ${_DEMO_SOURCES})
  else()
    add_executable(${_DEMO_NAME} ${_DEMO_SOURCES})
  endif()
  target_link_libraries(${_DEMO_NAME} PRIVATE cairo_imgui)
  target_include_directories(${_DEMO_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
  set_target_properties(${_DEMO_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY
                                                 ${CMAKE_BINARY_DIR}/bin)
  install(TARGETS ${_DEMO_NAME} RUNTIME DESTINATION bin)
endif()

# Asset path test executable
option(BUILD_ASSET_TEST "Build the asset path test executable" ON)
if(BUILD_ASSET_TEST)
  add_executable(test-asset-path test-asset-path.c)
  target_link_libraries(test-asset-path PRIVATE ${SDL3_TARGET} ${CAIRO_TARGET})
  if(NOT WIN32)
    target_link_libraries(test-asset-path PRIVATE m)
  endif()
  set_target_properties(test-asset-path PROPERTIES RUNTIME_OUTPUT_DIRECTORY
                                                    ${CMAKE_BINARY_DIR}/bin)
endif()

# Custom targets for development
if(BUILD_DEMO)
  add_custom_target(
    run
    COMMAND ${CMAKE_BINARY_DIR}/bin/cairo-imgui-demo
    DEPENDS cairo-imgui-demo
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running cairo-imgui-demo from project root (for asset paths)")
endif()

if(BUILD_ASSET_TEST)
  add_custom_target(
    test-assets
    COMMAND ${CMAKE_BINARY_DIR}/bin/test-asset-path
    DEPENDS test-asset-path
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running asset path test from project root")
endif()

# Style formatting with astyle (if available)
find_program(ASTYLE_EXECUTABLE astyle)
if(ASTYLE_EXECUTABLE)
  add_custom_target(
    style
    COMMAND ${ASTYLE_EXECUTABLE} -n *.c *.h
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Formatting source code with astyle")
endif()

# Static analysis with clang-tidy (if available)
find_program(CLANG_TIDY_EXECUTABLE clang-tidy)
if(CLANG_TIDY_EXECUTABLE)
  add_custom_target(
    tidy
    COMMAND ${CLANG_TIDY_EXECUTABLE} --use-color --quiet *.c --
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    DEPENDS ${PROJECT_NAME}
    COMMENT "Running clang-tidy static analysis")
endif()

# Print build information
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C compiler: ${CMAKE_C_COMPILER}")
message(STATUS "C flags: ${CMAKE_C_FLAGS}")
message(STATUS "Using SDL3 target: ${SDL3_TARGET}")
message(STATUS "Using Cairo target: ${CAIRO_TARGET}")
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  message(STATUS "Debug C flags: ${CMAKE_C_FLAGS_DEBUG}")
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
  message(STATUS "Release C flags: ${CMAKE_C_FLAGS_RELEASE}")
endif()
