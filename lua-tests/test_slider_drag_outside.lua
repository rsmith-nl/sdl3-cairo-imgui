#!/usr/bin/env luajit
-- Test dragging the slider knob continues updating even when mouse leaves slider rect
local ffi = require("ffi")
local sdlm = require("ffi_sdl3")
local gui = require("cairo_imgui")
local sdl = sdlm.sdl

local function assert_true(cond, msg)
    if not cond then
        io.stderr:write(string.format("[FAIL] %s\n", msg or 'assert_true failed'))
        os.exit(1)
    end
end

if not sdl.SDL_Init(sdlm.SDL_INIT_VIDEO) then
    io.stderr:write("ERROR: SDL_Init failed\n"); os.exit(1)
end
local window = ffi.new("SDL_Window*[1]")
local renderer = ffi.new("SDL_Renderer*[1]")
if not sdl.SDL_CreateWindowAndRenderer("Slider Drag Outside Test", 400, 200, 0, window, renderer) then
    io.stderr:write("ERROR: CreateWindowAndRenderer failed\n"); sdl.SDL_Quit(); os.exit(1)
end
local texture = sdl.SDL_CreateTexture(renderer[0], sdlm.SDL_PIXELFORMAT_ARGB8888, sdlm.SDL_TEXTUREACCESS_STREAMING, 400,
    200)

local ctx = gui.gui_context_new(); gui.gui_theme_dark(ctx)
local s = ffi.new("int[1]"); s[0] = 0

local x, y = 60, 50
local function begin_frame()
    gui.gui_begin(renderer[0], texture, ctx)
end
local function end_frame()
    gui.gui_slider(ctx, x, y, s)
    gui.gui_end(ctx)
end

-- Move mouse into slider knob area (initial knob at far left: knob spans x+4..x+24)
local ev = ffi.new("SDL_Event")
ev.type = sdlm.SDL_EVENT_MOUSE_MOTION; ev.motion.x = x + 10; ev.motion.y = y + 5; gui.gui_process_events(ctx, ev)
-- Press mouse down on knob
ev.type = sdlm.SDL_EVENT_MOUSE_BUTTON_DOWN; ev.button.x = x + 10; ev.button.y = y + 5; gui.gui_process_events(ctx, ev)
-- Render a frame to latch drag
begin_frame(); end_frame()

-- Drag far to the right beyond the slider width
for dx = 60, 400, 40 do
    ev.type = sdlm.SDL_EVENT_MOUSE_MOTION; ev.motion.x = x + dx; ev.motion.y = y + 5; gui.gui_process_events(ctx, ev)
    begin_frame(); end_frame()
end

-- Release outside the slider rect
ev.type = sdlm.SDL_EVENT_MOUSE_BUTTON_UP; ev.button.x = x + 400; ev.button.y = y + 5; gui.gui_process_events(ctx, ev)
begin_frame(); end_frame()

-- Expect the value to have increased to near the max (clamped)
assert_true(s[0] >= 200, "Slider should continue updating while dragging outside, nearing max")

sdl.SDL_DestroyTexture(texture); sdl.SDL_DestroyRenderer(renderer[0]); sdl.SDL_DestroyWindow(window[0]); sdl.SDL_Quit()
print("[PASS] Slider keeps updating when dragging outside the rect")
