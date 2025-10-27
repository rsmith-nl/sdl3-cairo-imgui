#!/usr/bin/env luajit
-- Simple test for editbox keyboard input
local ffi = require("ffi")
local sdlm = require("ffi_sdl3")
local gui = require("cairo_imgui")
local sdl = sdlm.sdl

print("=== Editbox Keyboard Test ===")

-- Setup SDL
if not sdl.SDL_Init(sdlm.SDL_INIT_VIDEO) then
    io.stderr:write("ERROR: SDL_Init failed\n")
    os.exit(1)
end

local window = ffi.new("SDL_Window*[1]")
local renderer = ffi.new("SDL_Renderer*[1]")
if not sdl.SDL_CreateWindowAndRenderer("Editbox Test", 400, 300, 0, window, renderer) then
    io.stderr:write("ERROR: CreateWindowAndRenderer failed\n")
    sdl.SDL_Quit(); os.exit(1)
end

local texture = sdl.SDL_CreateTexture(renderer[0], sdlm.SDL_PIXELFORMAT_ARGB8888,
    sdlm.SDL_TEXTUREACCESS_STREAMING, 400, 300)

-- GUI context
local ctx = gui.gui_context_new()
gui.gui_theme_dark(ctx)

-- Helper to simulate events
local function feed_event(ev_type, x, y, key, mod)
    local ev = ffi.new("SDL_Event")
    ev.type = ev_type
    if ev_type == sdlm.SDL_EVENT_MOUSE_MOTION then
        ev.motion.x = x; ev.motion.y = y
    elseif ev_type == sdlm.SDL_EVENT_MOUSE_BUTTON_DOWN or ev_type == sdlm.SDL_EVENT_MOUSE_BUTTON_UP then
        ev.button.x = x; ev.button.y = y
    elseif ev_type == sdlm.SDL_EVENT_KEY_UP or ev_type == sdlm.SDL_EVENT_KEY_DOWN then
        ev.key.key = key; ev.key.mod = mod or 0
    end
    gui.gui_process_events(ctx, ev)
end

-- Editbox state
local es = gui.gui_editstate_new()

print("\nTest 1: Click to focus editbox and type 'hi'")

-- Click on editbox to focus it
feed_event(sdlm.SDL_EVENT_MOUSE_MOTION, 200, 100)
feed_event(sdlm.SDL_EVENT_MOUSE_BUTTON_DOWN, 200, 100)
feed_event(sdlm.SDL_EVENT_MOUSE_BUTTON_UP, 200, 100)

gui.gui_begin(renderer[0], texture, ctx)
gui.gui_editbox(ctx, 150, 90, 100, es)
gui.gui_end(ctx)

-- Now type 'h' (use KEY_DOWN so key repeat is supported)
feed_event(sdlm.SDL_EVENT_KEY_DOWN, 0, 0, string.byte('h'))

gui.gui_begin(renderer[0], texture, ctx)
gui.gui_editbox(ctx, 150, 90, 100, es)
gui.gui_end(ctx)

-- Type 'i'
feed_event(sdlm.SDL_EVENT_KEY_DOWN, 0, 0, string.byte('i'))

gui.gui_begin(renderer[0], texture, ctx)
gui.gui_editbox(ctx, 150, 90, 100, es)
gui.gui_end(ctx)

-- Check result
local text = ffi.string(es.data, tonumber(es.used) or 0)
print("Typed text: '" .. text .. "'")

if text == "hi" then
    print("✓ Editbox accepted keyboard input correctly")
else
    print("✗ Expected 'hi', got '" .. text .. "'")
    os.exit(1)
end

-- Cleanup
sdl.SDL_DestroyTexture(texture)
sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()

print("\n=== Test PASSED ===")
