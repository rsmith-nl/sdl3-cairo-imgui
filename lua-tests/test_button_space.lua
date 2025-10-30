#!/usr/bin/env luajit
-- Test that Space activates a focused button
local ffi = require("ffi")
local sdlm = require("ffi_sdl3")
local gui = require("cairo_imgui")
local sdl = sdlm.sdl

local function assert_true(cond, msg)
    if not cond then
        io.stderr:write("[FAIL] " .. (msg or "") .. "\n"); os.exit(1)
    end
end

-- Setup SDL
if not sdl.SDL_Init(sdlm.SDL_INIT_VIDEO) then
    io.stderr:write("ERROR: SDL_Init failed\n"); os.exit(1)
end
local window = ffi.new("SDL_Window*[1]")
local renderer = ffi.new("SDL_Renderer*[1]")
if not sdl.SDL_CreateWindowAndRenderer("Button Space Test", 300, 200, 0, window, renderer) then
    io.stderr:write("ERROR: CreateWindowAndRenderer failed\n"); sdl.SDL_Quit(); os.exit(1)
end
local texture = sdl.SDL_CreateTexture(renderer[0], sdlm.SDL_PIXELFORMAT_ARGB8888, sdlm.SDL_TEXTUREACCESS_STREAMING, 300,
200)

-- Context
local ctx = gui.gui_context_new(); gui.gui_theme_dark(ctx)

-- Helper to send keydown
local function key_down(key)
    local ev = ffi.new("SDL_Event")
    ev.type = sdlm.SDL_EVENT_KEY_DOWN
    ev.key.key = key
    ev.key.mod = 0
    gui.gui_process_events(ctx, ev)
end

-- Focus the first widget (button)
ctx.id = 1

-- Frame: draw button then press Space to activate
gui.gui_begin(renderer[0], texture, ctx)
local clicked = gui.gui_button(ctx, 50, 50, "Press")
gui.gui_end(ctx)

-- Not clicked yet
assert_true(not clicked, "Button should not have clicked before Space")

-- Press Space
key_down(sdlm.SDLK_SPACE)

gui.gui_begin(renderer[0], texture, ctx)
clicked = gui.gui_button(ctx, 50, 50, "Press")
gui.gui_end(ctx)

assert_true(clicked, "Button should click on Space when focused")

sdl.SDL_DestroyTexture(texture)
sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()

print("[PASS] Space activates focused button")
