#!/usr/bin/env luajit
-- Verify that gui_radiobuttons returns true and updates selection when navigating with LEFT/RIGHT
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
if not sdl.SDL_CreateWindowAndRenderer("Radio LR Nav Test", 400, 300, 0, window, renderer) then
    io.stderr:write("ERROR: CreateWindowAndRenderer failed\n")
    sdl.SDL_Quit(); os.exit(1)
end
local texture = sdl.SDL_CreateTexture(renderer[0], sdlm.SDL_PIXELFORMAT_ARGB8888,
    sdlm.SDL_TEXTUREACCESS_STREAMING, 400, 300)

-- GUI context
local ctx = gui.gui_context_new()
ctx.id = 1 -- focus on the radio group

-- Prepare labels and state
local labels = { "opt0", "opt1", "opt2" }
local state = ffi.new("int[1]")
state[0] = 0 -- start at opt0

-- Helper to send a key event
local function key_down(key)
    local ev = ffi.new("SDL_Event")
    ev.type = sdlm.SDL_EVENT_KEY_DOWN
    ev.key.key = key
    ev.key.mod = 0
    gui.gui_process_events(ctx, ev)
end

-- Draw one frame and return changed flag
local function frame()
    gui.gui_begin(renderer[0], texture, ctx)
    local changed = gui.gui_radiobuttons(ctx, 20, 20, labels, state)
    gui.gui_end(ctx)
    return changed
end

-- Baseline
assert_eq(frame(), false, "No change on baseline frame")

-- RIGHT: 0 -> 1
key_down(sdlm.SDLK_RIGHT)
local changed = frame()
assert_eq(changed, true, "RIGHT should report change")
assert_eq(state[0], 1, "RIGHT should select opt1")

-- RIGHT: 1 -> 2
key_down(sdlm.SDLK_RIGHT)
changed = frame()
assert_eq(changed, true, "RIGHT should report change")
assert_eq(state[0], 2, "RIGHT should select opt2")

-- RIGHT wrap: 2 -> 0
key_down(sdlm.SDLK_RIGHT)
changed = frame()
assert_eq(changed, true, "RIGHT wrap should report change")
assert_eq(state[0], 0, "RIGHT wrap should select opt0")

-- LEFT: 0 -> 2 (wrap backward)
key_down(sdlm.SDLK_LEFT)
changed = frame()
assert_eq(changed, true, "LEFT wrap should report change")
assert_eq(state[0], 2, "LEFT wrap should select opt2")

-- Cleanup
sdl.SDL_DestroyTexture(texture)
sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()

print("[PASS] Radio buttons LEFT/RIGHT navigation returns true and updates selection (with wrapping)")
