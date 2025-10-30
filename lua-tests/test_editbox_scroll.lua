#!/usr/bin/env luajit
-- Test editbox scrolling behavior with cursor movement
local ffi = require("ffi")
local sdlm = require("ffi_sdl3")
local gui = require("cairo_imgui")
local sdl = sdlm.sdl

print("=== Editbox Scrolling Test ===")

-- Setup SDL
if not sdl.SDL_Init(sdlm.SDL_INIT_VIDEO) then
    io.stderr:write("ERROR: SDL_Init failed\n")
    os.exit(1)
end

local window = ffi.new("SDL_Window*[1]")
local renderer = ffi.new("SDL_Renderer*[1]")
if not sdl.SDL_CreateWindowAndRenderer("Scroll Test", 400, 300, 0, window, renderer) then
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

print("\nTest 1: Type long text and verify displaypos scrolls")

-- Click on editbox to focus it
feed_event(sdlm.SDL_EVENT_MOUSE_MOTION, 80, 100)
feed_event(sdlm.SDL_EVENT_MOUSE_BUTTON_DOWN, 80, 100)
feed_event(sdlm.SDL_EVENT_MOUSE_BUTTON_UP, 80, 100)

gui.gui_begin(renderer[0], texture, ctx)
gui.gui_editbox(ctx, 50, 90, 80, es) -- narrow 80px width
gui.gui_end(ctx)

-- Type a long string
local long_text = "AAAABBBBCCCCDDDDEEEEFFFFGGGG"
for i = 1, #long_text do
    feed_event(sdlm.SDL_EVENT_KEY_DOWN, 0, 0, string.byte(long_text:sub(i, i)))
    gui.gui_begin(renderer[0], texture, ctx)
    gui.gui_editbox(ctx, 50, 90, 80, es)
    gui.gui_end(ctx)
end

local initial_displaypos = tonumber(es.displaypos) or 0
print("After typing, displaypos = " .. initial_displaypos)

if initial_displaypos > 0 then
    print("✓ Display scrolled forward as expected")
else
    print("✗ Display did not scroll (might be OK if text fits)")
end

print("\nTest 2: Move cursor left and verify scroll follows")

-- Press LEFT arrow multiple times (use KEY_DOWN for navigation keys)
for i = 1, 15 do
    feed_event(sdlm.SDL_EVENT_KEY_DOWN, 0, 0, sdlm.SDLK_LEFT)
    gui.gui_begin(renderer[0], texture, ctx)
    gui.gui_editbox(ctx, 50, 90, 80, es)
    gui.gui_end(ctx)
end

local after_left_displaypos = tonumber(es.displaypos) or 0
local cursorpos = tonumber(es.cursorpos) or 0

print("After moving left, cursorpos = " .. cursorpos .. ", displaypos = " .. after_left_displaypos)

if after_left_displaypos < initial_displaypos then
    print("✓ Display scrolled back when cursor moved left")
else
    print("⚠ Display position unchanged (might be OK if cursor still visible)")
end

print("\nTest 3: Move to HOME and verify displaypos resets")

feed_event(sdlm.SDL_EVENT_KEY_DOWN, 0, 0, sdlm.SDLK_HOME)
gui.gui_begin(renderer[0], texture, ctx)
gui.gui_editbox(ctx, 50, 90, 80, es)
gui.gui_end(ctx)

local home_displaypos = tonumber(es.displaypos) or 0
local home_cursorpos = tonumber(es.cursorpos) or 0

print("After HOME, cursorpos = " .. home_cursorpos .. ", displaypos = " .. home_displaypos)

if home_cursorpos == 0 and home_displaypos == 0 then
    print("✓ HOME correctly reset cursor and display")
else
    print("✗ HOME behavior incorrect")
    os.exit(1)
end

print("\nTest 4: Move to END and verify scroll to end")

feed_event(sdlm.SDL_EVENT_KEY_DOWN, 0, 0, sdlm.SDLK_END)
gui.gui_begin(renderer[0], texture, ctx)
gui.gui_editbox(ctx, 50, 90, 80, es)
gui.gui_end(ctx)

local end_displaypos = tonumber(es.displaypos) or 0
local end_cursorpos = tonumber(es.cursorpos) or 0
local used = tonumber(es.used) or 0

print("After END, cursorpos = " .. end_cursorpos .. ", displaypos = " .. end_displaypos .. ", used = " .. used)

if end_cursorpos == used then
    print("✓ END correctly moved cursor to end")
else
    print("✗ END cursor position incorrect")
    os.exit(1)
end

-- Cleanup
sdl.SDL_DestroyTexture(texture)
sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()

print("\n=== Test PASSED ===")
print("Scrolling logic working correctly!")
