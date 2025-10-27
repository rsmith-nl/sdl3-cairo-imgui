#!/usr/bin/env luajit
-- Automated test for gui_button click behavior in Lua port
-- Verifies: click triggers only when mouse is released inside the button

local ffi = require("ffi")
local sdlm = require("ffi_sdl3")
local gui = require("cairo_imgui")
local sdl = sdlm.sdl

local function assert_true(cond, msg)
    if not cond then
        io.stderr:write("[FAIL] " .. msg .. "\n")
        os.exit(1)
    end
end

local function assert_false(cond, msg)
    if cond then
        io.stderr:write("[FAIL] " .. msg .. "\n")
        os.exit(1)
    end
end

-- Setup SDL
if not sdl.SDL_Init(sdlm.SDL_INIT_VIDEO) then
    io.stderr:write("ERROR: SDL_Init failed: " .. ffi.string(sdl.SDL_GetError()) .. "\n")
    os.exit(1)
end

local window = ffi.new("SDL_Window*[1]")
local renderer = ffi.new("SDL_Renderer*[1]")
local W, H = 400, 300
if not sdl.SDL_CreateWindowAndRenderer("Lua Button Test", W, H, 0, window, renderer) then
    io.stderr:write("ERROR: SDL_CreateWindowAndRenderer failed: " .. ffi.string(sdl.SDL_GetError()) .. "\n")
    sdl.SDL_Quit(); os.exit(1)
end

local texture = sdl.SDL_CreateTexture(renderer[0], sdlm.SDL_PIXELFORMAT_ARGB8888, sdlm.SDL_TEXTUREACCESS_STREAMING, W, H)
assert_true(texture ~= nil, "SDL_CreateTexture returned nil")

-- GUI context
local ctx = gui.gui_context_new()
gui.gui_theme_dark(ctx)

-- Helpers to feed events directly to gui_process_events
local function mouse_motion(x, y)
    local ev = ffi.new("SDL_Event")
    ev.type = sdlm.SDL_EVENT_MOUSE_MOTION
    ev.motion.x = x; ev.motion.y = y
    gui.gui_process_events(ctx, ev)
end

local function mouse_down(x, y)
    local ev = ffi.new("SDL_Event")
    ev.type = sdlm.SDL_EVENT_MOUSE_BUTTON_DOWN
    ev.button.x = x; ev.button.y = y
    gui.gui_process_events(ctx, ev)
end

local function mouse_up(x, y)
    local ev = ffi.new("SDL_Event")
    ev.type = sdlm.SDL_EVENT_MOUSE_BUTTON_UP
    ev.button.x = x; ev.button.y = y
    gui.gui_process_events(ctx, ev)
end

-- Common begin/end frame
local function begin_frame()
    gui.gui_begin(renderer[0], texture, ctx)
end
local function end_frame()
    gui.gui_end(ctx)
end

-- Button under test at (10,10)
local BX, BY = 10, 10

-- Test 1: Release INSIDE should click
mouse_motion(BX + 15, BY + 15)
mouse_down(BX + 15, BY + 15)
mouse_up(BX + 15, BY + 15)

begin_frame()
local clicked_inside = gui.gui_button(ctx, BX, BY, "Test")
end_frame()

assert_true(clicked_inside, "Button should click when released inside")

-- Test 2: Release OUTSIDE should not click
mouse_motion(BX + 15, BY + 15)
mouse_down(BX + 15, BY + 15)
mouse_motion(BX + 300, BY + 200) -- drag outside
mouse_up(BX + 300, BY + 200)

begin_frame()
local clicked_outside = gui.gui_button(ctx, BX, BY, "Test")
end_frame()

assert_false(clicked_outside, "Button should not click when released outside")

-- Cleanup
sdl.SDL_DestroyTexture(texture)
sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()

print("[PASS] Button click behavior matches expectation (inside-only)")
