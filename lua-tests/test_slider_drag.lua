#!/usr/bin/env luajit
-- Test dragging the slider with mouse updates its value
local ffi = require("ffi")
local sdlm = require("ffi_sdl3")
local gui = require("cairo_imgui")
local sdl = sdlm.sdl

local function assert_eq(a, b, msg)
    if a ~= b then
        io.stderr:write(string.format("[FAIL] %s (got=%s expected=%s)\n", msg or '', tostring(a), tostring(b)))
        os.exit(1)
    end
end

if not sdl.SDL_Init(sdlm.SDL_INIT_VIDEO) then
    io.stderr:write("ERROR: SDL_Init failed\n"); os.exit(1)
end
local window = ffi.new("SDL_Window*[1]")
local renderer = ffi.new("SDL_Renderer*[1]")
if not sdl.SDL_CreateWindowAndRenderer("Slider Drag Test", 400, 200, 0, window, renderer) then
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

-- Move mouse into slider area
local ev = ffi.new("SDL_Event")
ev.type = sdlm.SDL_EVENT_MOUSE_MOTION; ev.motion.x = x + 10; ev.motion.y = y + 5; gui.gui_process_events(ctx, ev)

-- Press mouse down
ev.type = sdlm.SDL_EVENT_MOUSE_BUTTON_DOWN; ev.button.x = x + 10; ev.button.y = y + 5; gui.gui_process_events(ctx, ev)

-- Frame after press
begin_frame(); end_frame()

-- Drag to the right in steps
for dx = 50, 120, 10 do
    ev.type = sdlm.SDL_EVENT_MOUSE_MOTION; ev.motion.x = x + dx; ev.motion.y = y + 5; gui.gui_process_events(ctx, ev)
    begin_frame(); end_frame()
end

-- Release mouse
ev.type = sdlm.SDL_EVENT_MOUSE_BUTTON_UP; ev.button.x = x + 120; ev.button.y = y + 5; gui.gui_process_events(ctx, ev)
begin_frame(); end_frame()

-- Expect slider near 120 - offset - xsize/2 (approx). We only assert it increased significantly
assert_eq(s[0] > 40, true, "Slider value should increase after drag")

sdl.SDL_DestroyTexture(texture); sdl.SDL_DestroyRenderer(renderer[0]); sdl.SDL_DestroyWindow(window[0]); sdl.SDL_Quit()
print("[PASS] Slider is draggable by mouse drag")
