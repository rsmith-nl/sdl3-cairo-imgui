#!/usr/bin/env luajit
-- Test editbox key repeat behavior
local ffi = require("ffi")
local sdlm = require("ffi_sdl3")
local gui = require("cairo_imgui")
local sdl = sdlm.sdl

print("=== Editbox Key Repeat Test ===")

-- Setup SDL
if not sdl.SDL_Init(sdlm.SDL_INIT_VIDEO) then
    io.stderr:write("ERROR: SDL_Init failed\n")
    os.exit(1)
end

local window = ffi.new("SDL_Window*[1]")
local renderer = ffi.new("SDL_Renderer*[1]")
if not sdl.SDL_CreateWindowAndRenderer("Key Repeat Test", 400, 300, 0, window, renderer) then
    io.stderr:write("ERROR: CreateWindowAndRenderer failed\n")
    sdl.SDL_Quit(); os.exit(1)
end

local texture = sdl.SDL_CreateTexture(renderer[0], sdlm.SDL_PIXELFORMAT_ARGB8888,
    sdlm.SDL_TEXTUREACCESS_STREAMING, 400, 300)

-- GUI context
local ctx = gui.gui_context_new()
gui.gui_theme_dark(ctx)

-- Helper to simulate events
local function feed_event(ev_type, x, y, key, mod, is_repeat)
    local ev = ffi.new("SDL_Event")
    ev.type = ev_type
    if ev_type == sdlm.SDL_EVENT_MOUSE_MOTION then
        ev.motion.x = x; ev.motion.y = y
    elseif ev_type == sdlm.SDL_EVENT_MOUSE_BUTTON_DOWN or ev_type == sdlm.SDL_EVENT_MOUSE_BUTTON_UP then
        ev.button.x = x; ev.button.y = y
    elseif ev_type == sdlm.SDL_EVENT_KEY_UP or ev_type == sdlm.SDL_EVENT_KEY_DOWN then
        ev.key.key = key
        ev.key.mod = mod or 0
        ev.key['repeat'] = is_repeat and 1 or 0
    end
    gui.gui_process_events(ctx, ev)
end

-- Editbox state
local es = gui.gui_editstate_new()

print("\nTest 1: Simulate holding RIGHT arrow (key repeat)")

-- Click on editbox to focus it
feed_event(sdlm.SDL_EVENT_MOUSE_MOTION, 80, 100)
feed_event(sdlm.SDL_EVENT_MOUSE_BUTTON_DOWN, 80, 100)
feed_event(sdlm.SDL_EVENT_MOUSE_BUTTON_UP, 80, 100)

gui.gui_begin(renderer[0], texture, ctx)
gui.gui_editbox(ctx, 50, 90, 100, es)
gui.gui_end(ctx)

-- Type some text
local text = "HelloWorld1234567890"
for i = 1, #text do
    feed_event(sdlm.SDL_EVENT_KEY_DOWN, 0, 0, string.byte(text:sub(i, i)))
    gui.gui_begin(renderer[0], texture, ctx)
    gui.gui_editbox(ctx, 50, 90, 100, es)
    gui.gui_end(ctx)
end

print("Typed: '" .. ffi.string(es.data, es.used) .. "'")
print("Initial cursorpos: " .. tonumber(es.cursorpos))

-- Move to HOME first
feed_event(sdlm.SDL_EVENT_KEY_DOWN, 0, 0, sdlm.SDLK_HOME)
gui.gui_begin(renderer[0], texture, ctx)
gui.gui_editbox(ctx, 50, 90, 100, es)
gui.gui_end(ctx)

print("After HOME, cursorpos: " .. tonumber(es.cursorpos))

-- Simulate holding RIGHT arrow (initial press + repeats)
feed_event(sdlm.SDL_EVENT_KEY_DOWN, 0, 0, sdlm.SDLK_RIGHT, 0, false) -- initial press
gui.gui_begin(renderer[0], texture, ctx)
gui.gui_editbox(ctx, 50, 90, 100, es)
gui.gui_end(ctx)

for i = 1, 5 do
    feed_event(sdlm.SDL_EVENT_KEY_DOWN, 0, 0, sdlm.SDLK_RIGHT, 0, true) -- repeat
    gui.gui_begin(renderer[0], texture, ctx)
    gui.gui_editbox(ctx, 50, 90, 100, es)
    gui.gui_end(ctx)
end

feed_event(sdlm.SDL_EVENT_KEY_UP, 0, 0, sdlm.SDLK_RIGHT) -- release
gui.gui_begin(renderer[0], texture, ctx)
gui.gui_editbox(ctx, 50, 90, 100, es)
gui.gui_end(ctx)

print("After holding RIGHT (6 times), cursorpos: " .. tonumber(es.cursorpos))

if tonumber(es.cursorpos) == 6 then
    print("✓ Key repeat worked correctly")
else
    print("✗ Expected cursorpos=6, got " .. tonumber(es.cursorpos))
    os.exit(1)
end

print("\nTest 2: Simulate holding BACKSPACE (key repeat)")

-- Current position is 6, delete 3 chars with repeat
feed_event(sdlm.SDL_EVENT_KEY_DOWN, 0, 0, sdlm.SDLK_BACKSPACE, 0, false) -- initial
gui.gui_begin(renderer[0], texture, ctx)
gui.gui_editbox(ctx, 50, 90, 100, es)
gui.gui_end(ctx)

for i = 1, 2 do
    feed_event(sdlm.SDL_EVENT_KEY_DOWN, 0, 0, sdlm.SDLK_BACKSPACE, 0, true) -- repeat
    gui.gui_begin(renderer[0], texture, ctx)
    gui.gui_editbox(ctx, 50, 90, 100, es)
    gui.gui_end(ctx)
end

feed_event(sdlm.SDL_EVENT_KEY_UP, 0, 0, sdlm.SDLK_BACKSPACE) -- release
gui.gui_begin(renderer[0], texture, ctx)
gui.gui_editbox(ctx, 50, 90, 100, es)
gui.gui_end(ctx)

local remaining = ffi.string(es.data, es.used)
print("After 3 backspaces, text: '" .. remaining .. "'")
print("Cursorpos: " .. tonumber(es.cursorpos))

if remaining == "Helorld1234567890" and tonumber(es.cursorpos) == 3 then
    print("✓ Backspace repeat worked correctly")
else
    print("✗ Text/cursor incorrect")
    os.exit(1)
end

-- Cleanup
sdl.SDL_DestroyTexture(texture)
sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()

print("\n=== Test PASSED ===")
print("Key repeat for navigation and editing keys works!")
