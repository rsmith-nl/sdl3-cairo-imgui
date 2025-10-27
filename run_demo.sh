#!/bin/bash
# run_demo.sh
# Launcher script for the Lua Cairo ImGui demo
# This is free and unencumbered software released into the public domain.

# Set library path if needed (adjust for your system)
# export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Run the demo with LuaJIT
exec luajit demo.lua "$@"
