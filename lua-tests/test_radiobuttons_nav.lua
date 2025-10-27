#!/usr/bin/env luajit
-- Verify that gui_radiobuttons returns true and updates selection when navigating with UP/DOWN
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
if not sdl.SDL_CreateWindowAndRenderer("Radio Nav Test", 400, 300, 0, window, renderer) then
    io.stderr:write("ERROR: CreateWindowAndRenderer failed\n")
    sdl.SDL_Quit(); os.exit(1)
end
local texture = sdl.SDL_CreateTexture(renderer[0], sdlm.SDL_PIXELFORMAT_ARGB8888,
    sdlm.SDL_TEXTUREACCESS_STREAMING, 400, 300)

-- GUI context
local ctx = gui.gui_context_new()
ctx.id = 1 -- focus on first widget drawn

-- Prepare labels and state
local labels = { "opt0", "opt1", "opt2" }
local state = ffi.new("int[1]")
state[0] = 1 -- currently on opt1

-- Helper to send a key event
local function key_down(key)
    local ev = ffi.new("SDL_Event")
    ev.type = sdlm.SDL_EVENT_KEY_DOWN
    ev.key.key = key
    ev.key.mod = 0
    gui.gui_process_events(ctx, ev)
end

-- Draw and test
local function frame()
    gui.gui_begin(renderer[0], texture, ctx)
    local changed = gui.gui_radiobuttons(ctx, 20, 20, labels, state)
    gui.gui_end(ctx)
    return changed
end

-- Frame 1: baseline
assert_eq(frame(), false, "No change on baseline frame")

-- DOWN: should go from 1 -> 2, return true
key_down(sdlm.SDLK_DOWN)
local changed = frame()
assert_eq(changed, true, "DOWN should report change")
assert_eq(state[0], 2, "DOWN should select opt2")

-- UP: should go from 2 -> 1, return true
key_down(sdlm.SDLK_UP)
changed = frame()
assert_eq(changed, true, "UP should report change")
assert_eq(state[0], 1, "UP should select opt1")

-- Cleanup
sdl.SDL_DestroyTexture(texture)
sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()

print("[PASS] Radio buttons navigation returns true and updates selection")
