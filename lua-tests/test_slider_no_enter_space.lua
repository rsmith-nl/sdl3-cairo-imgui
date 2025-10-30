#!/usr/bin/env luajit
-- Ensure slider does not activate on Enter/Space (only mouse and arrows)
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

-- Setup SDL
if not sdl.SDL_Init(sdlm.SDL_INIT_VIDEO) then
    io.stderr:write("ERROR: SDL_Init failed\n")
    os.exit(1)
end
local window = ffi.new("SDL_Window*[1]")
local renderer = ffi.new("SDL_Renderer*[1]")
if not sdl.SDL_CreateWindowAndRenderer("Slider No Enter/Space", 400, 200, 0, window, renderer) then
    io.stderr:write("ERROR: CreateWindowAndRenderer failed\n")
    sdl.SDL_Quit(); os.exit(1)
end
local texture = sdl.SDL_CreateTexture(renderer[0], sdlm.SDL_PIXELFORMAT_ARGB8888, sdlm.SDL_TEXTUREACCESS_STREAMING, 400,
    200)

-- Context
local ctx = gui.gui_context_new(); gui.gui_theme_dark(ctx)

-- Slider state
local s = ffi.new("int[1]"); s[0] = 10

-- Focus the slider (draw it as the first widget so its id=1)
ctx.id = 1

local function frame()
    gui.gui_begin(renderer[0], texture, ctx)
    gui.gui_slider(ctx, 60, 16, s)
    gui.gui_end(ctx)
end

frame()
-- Press Enter, expect no change
local ev = ffi.new("SDL_Event"); ev.type = sdlm.SDL_EVENT_KEY_DOWN; ev.key.key = sdlm.SDLK_RETURN; ev.key.mod = 0; gui
    .gui_process_events(ctx, ev)
frame()
assert_eq(s[0], 10, "Slider should not react to Enter")

-- Press Space, expect no change
ev.key.key = sdlm.SDLK_SPACE; gui.gui_process_events(ctx, ev)
frame()
assert_eq(s[0], 10, "Slider should not react to Space")

-- Arrow Right should change
ev.key.key = sdlm.SDLK_RIGHT; gui.gui_process_events(ctx, ev)
frame()
assert_eq(s[0], 11, "Slider should react to Right arrow")

sdl.SDL_DestroyTexture(texture)
sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()

print("[PASS] Slider ignores Enter/Space; reacts to arrows only")
