#!/usr/bin/env luajit
-- Simple test: gui_button in Lua only triggers on mouse release inside the button area

local ffi = require("ffi")
local sdlm = require("ffi_sdl3")
local gui = require("cairo_imgui")
local sdl = sdlm.sdl

print("=== Simple Lua Button Widget Test ===")

-- Setup SDL
if not sdl.SDL_Init(sdlm.SDL_INIT_VIDEO) then
    io.stderr:write("ERROR: SDL_Init failed\n")
    os.exit(1)
end

local window = ffi.new("SDL_Window*[1]")
local renderer = ffi.new("SDL_Renderer*[1]")
if not sdl.SDL_CreateWindowAndRenderer("Button Test", 400, 300, 0, window, renderer) then
    io.stderr:write("ERROR: CreateWindowAndRenderer failed\n")
    sdl.SDL_Quit(); os.exit(1)
end

local texture = sdl.SDL_CreateTexture(renderer[0], sdlm.SDL_PIXELFORMAT_ARGB8888,
    sdlm.SDL_TEXTUREACCESS_STREAMING, 400, 300)

-- GUI context
local ctx = gui.gui_context_new()
gui.gui_theme_dark(ctx)

-- Helper to simulate events
local function feed_event(ev_type, x, y, key)
    local ev = ffi.new("SDL_Event")
    ev.type = ev_type
    if ev_type == sdlm.SDL_EVENT_MOUSE_MOTION then
        ev.motion.x = x; ev.motion.y = y
    elseif ev_type == sdlm.SDL_EVENT_MOUSE_BUTTON_DOWN or ev_type == sdlm.SDL_EVENT_MOUSE_BUTTON_UP then
        ev.button.x = x; ev.button.y = y
    elseif ev_type == sdlm.SDL_EVENT_KEY_UP or ev_type == sdlm.SDL_EVENT_KEY_DOWN then
        ev.key.key = key; ev.key.mod = 0
    end
    gui.gui_process_events(ctx, ev)
end

-- Test button at position (50, 50)
local BTN_X, BTN_Y = 50, 50
local BTN_LABEL = "Click Me"

print("\nTest 1: Click and release INSIDE button")
feed_event(sdlm.SDL_EVENT_MOUSE_MOTION, BTN_X + 30, BTN_Y + 10)
feed_event(sdlm.SDL_EVENT_MOUSE_BUTTON_DOWN, BTN_X + 30, BTN_Y + 10)
feed_event(sdlm.SDL_EVENT_MOUSE_BUTTON_UP, BTN_X + 30, BTN_Y + 10)

gui.gui_begin(renderer[0], texture, ctx)
local clicked = gui.gui_button(ctx, BTN_X, BTN_Y, BTN_LABEL)
gui.gui_end(ctx)

if clicked then
    print("✓ Button clicked (expected)")
else
    print("✗ Button NOT clicked (unexpected)")
    os.exit(1)
end

print("\nTest 2: Click inside, drag and release OUTSIDE button")
feed_event(sdlm.SDL_EVENT_MOUSE_MOTION, BTN_X + 30, BTN_Y + 10)
feed_event(sdlm.SDL_EVENT_MOUSE_BUTTON_DOWN, BTN_X + 30, BTN_Y + 10)
feed_event(sdlm.SDL_EVENT_MOUSE_MOTION, BTN_X + 200, BTN_Y + 200) -- drag outside
feed_event(sdlm.SDL_EVENT_MOUSE_BUTTON_UP, BTN_X + 200, BTN_Y + 200)

gui.gui_begin(renderer[0], texture, ctx)
clicked = gui.gui_button(ctx, BTN_X, BTN_Y, BTN_LABEL)
gui.gui_end(ctx)

if not clicked then
    print("✓ Button NOT clicked (expected)")
else
    print("✗ Button clicked (unexpected)")
    os.exit(1)
end

print("\nTest 3: Click and release completely OUTSIDE button")
feed_event(sdlm.SDL_EVENT_MOUSE_MOTION, BTN_X + 200, BTN_Y + 200) -- far outside
feed_event(sdlm.SDL_EVENT_MOUSE_BUTTON_DOWN, BTN_X + 200, BTN_Y + 200)
feed_event(sdlm.SDL_EVENT_MOUSE_BUTTON_UP, BTN_X + 200, BTN_Y + 200)

gui.gui_begin(renderer[0], texture, ctx)
clicked = gui.gui_button(ctx, BTN_X, BTN_Y, BTN_LABEL)
gui.gui_end(ctx)

if not clicked then
    print("✓ Button NOT clicked (expected)")
else
    print("✗ Button clicked when clicking outside (unexpected)")
    os.exit(1)
end

print("\nTest 4: Keyboard activation with Enter (when focused)")
-- Tab to focus the button (it's the first widget, id=1)
ctx.id = 1
feed_event(sdlm.SDL_EVENT_KEY_DOWN, 0, 0, sdlm.SDLK_RETURN)

gui.gui_begin(renderer[0], texture, ctx)
clicked = gui.gui_button(ctx, BTN_X, BTN_Y, BTN_LABEL)
gui.gui_end(ctx)

if clicked then
    print("✓ Button clicked via Enter (expected)")
else
    print("✗ Button NOT clicked via Enter (unexpected)")
    os.exit(1)
end

-- Cleanup
sdl.SDL_DestroyTexture(texture)
sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()

print("\n=== All Tests PASSED ===")
