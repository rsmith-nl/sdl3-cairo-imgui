cmake_minimum_required(VERSION 3.20)

# Project configuration
project(
  cairo-imgui-demo
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

# Find required packages
find_package(PkgConfig REQUIRED)

# Find SDL3
pkg_check_modules(SDL3 REQUIRED IMPORTED_TARGET sdl3)
if(NOT SDL3_FOUND)
  message(
    FATAL_ERROR "SDL3 not found. Please install SDL3 development libraries.")
endif()

# Find Cairo
pkg_check_modules(CAIRO REQUIRED IMPORTED_TARGET cairo)
if(NOT CAIRO_FOUND)
  message(
    FATAL_ERROR "Cairo not found. Please install Cairo development libraries.")
endif()

# Source files
set(SOURCES cairo-imgui-demo.c cairo-imgui.c)

set(HEADERS cairo-imgui.h)

# Create executable
add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS})

# Link libraries
target_link_libraries(
  ${PROJECT_NAME} PRIVATE PkgConfig::SDL3 PkgConfig::CAIRO m # math library
)

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

# Set output directory
set_target_properties(${PROJECT_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY
                                                 ${CMAKE_BINARY_DIR}/bin)

# Install rules
install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION bin)

# Custom targets for development
add_custom_target(
  run
  COMMAND ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}
  DEPENDS ${PROJECT_NAME}
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/bin
  COMMENT "Running ${PROJECT_NAME}")

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
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  message(STATUS "Debug C flags: ${CMAKE_C_FLAGS_DEBUG}")
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
  message(STATUS "Release C flags: ${CMAKE_C_FLAGS_RELEASE}")
endif()
