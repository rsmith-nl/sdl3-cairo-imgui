#!/usr/bin/env luajit
-- Test Tab focus cycling (including repeat) across widgets
local ffi = require("ffi")
local bit = require("bit")
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
if not sdl.SDL_CreateWindowAndRenderer("Tab Cycle Test", 400, 300, 0, window, renderer) then
    io.stderr:write("ERROR: CreateWindowAndRenderer failed\n")
    sdl.SDL_Quit(); os.exit(1)
end

local texture = sdl.SDL_CreateTexture(renderer[0], sdlm.SDL_PIXELFORMAT_ARGB8888,
    sdlm.SDL_TEXTUREACCESS_STREAMING, 400, 300)

-- GUI context
local ctx = gui.gui_context_new()
gui.gui_theme_dark(ctx)

-- Helper to feed a key event to the GUI
local function key_event(down, key, mod)
    local ev = ffi.new("SDL_Event")
    ev.type = down and sdlm.SDL_EVENT_KEY_DOWN or sdlm.SDL_EVENT_KEY_UP
    ev.key.key = key
    ev.key.mod = mod or 0
    gui.gui_process_events(ctx, ev)
end

-- Draw a frame with three buttons to define focusable ids 1..3
local function draw_frame()
    gui.gui_begin(renderer[0], texture, ctx)
    gui.gui_button(ctx, 50, 50, "Btn1")  -- id=1
    gui.gui_button(ctx, 50, 100, "Btn2") -- id=2
    gui.gui_button(ctx, 50, 150, "Btn3") -- id=3
    gui.gui_end(ctx)
end

-- Initial frame to set maxid
draw_frame()

-- Start with focus on id=1
ctx.id = 1

-- Press Tab 1x -> id=2
key_event(true, sdlm.SDLK_TAB)
draw_frame()
assert_eq(ctx.id, 2, "Tab once should focus id=2")

-- Press Tab 2x more -> id=3 then wrap to id=1
key_event(true, sdlm.SDLK_TAB)
draw_frame()
assert_eq(ctx.id, 3, "Tab twice should focus id=3")

key_event(true, sdlm.SDLK_TAB)
draw_frame()
assert_eq(ctx.id, 1, "Tab three times should wrap to id=1")

-- Shift+Tab should go backwards: from 1 -> 3
key_event(true, sdlm.SDLK_TAB, sdlm.SDL_KMOD_LSHIFT)
draw_frame()
assert_eq(ctx.id, 3, "Shift+Tab from 1 should wrap to id=3")

-- Shift+Tab again: 3 -> 2
key_event(true, sdlm.SDLK_TAB, sdlm.SDL_KMOD_LSHIFT)
draw_frame()
assert_eq(ctx.id, 2, "Shift+Tab from 3 should go to id=2")

-- Cleanup
sdl.SDL_DestroyTexture(texture)
sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()

print("[PASS] Tab focus cycling works (with repeat and wrapping)")
