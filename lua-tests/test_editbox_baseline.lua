#!/usr/bin/env luajit
-- Visual test for text baseline consistency
local ffi = require("ffi")
local sdlm = require("ffi_sdl3")
local gui = require("cairo_imgui")
local sdl = sdlm.sdl

print("=== Editbox Baseline Test ===")
print("This creates a window showing text with mixed character heights.")
print("The baseline should remain consistent (not jump up/down).")
print("Press ESC to close the window.\n")

-- Setup SDL
if not sdl.SDL_Init(sdlm.SDL_INIT_VIDEO) then
    io.stderr:write("ERROR: SDL_Init failed\n")
    os.exit(1)
end

local window = ffi.new("SDL_Window*[1]")
local renderer = ffi.new("SDL_Renderer*[1]")
if not sdl.SDL_CreateWindowAndRenderer("Baseline Test - Type mixed a/b/g/y text", 600, 400, 0, window, renderer) then
    io.stderr:write("ERROR: CreateWindowAndRenderer failed\n")
    sdl.SDL_Quit(); os.exit(1)
end

sdl.SDL_RaiseWindow(window[0])

local texture = sdl.SDL_CreateTexture(renderer[0], sdlm.SDL_PIXELFORMAT_ARGB8888,
    sdlm.SDL_TEXTUREACCESS_STREAMING, 600, 400)
sdl.SDL_SetTextureBlendMode(texture, sdlm.SDL_BLENDMODE_NONE)

-- GUI context
local ctx = gui.gui_context_new()
gui.gui_theme_dark(ctx)

-- Create multiple editboxes with different test text
local es1 = gui.gui_editstate_new()
local es2 = gui.gui_editstate_new()
local es3 = gui.gui_editstate_new()

-- Pre-fill with test text
local function fill_editbox(state, text)
    for i = 1, #text do
        state.data[i - 1] = string.byte(text:sub(i, i))
    end
    state.used = #text
    state.cursorpos = #text
end

fill_editbox(es1, "aaaa")
fill_editbox(es2, "bbbb")
fill_editbox(es3, "aabb")

print("Window opened. Observe the text baseline:")
print("  Box 1: 'aaaa' (short letters)")
print("  Box 2: 'bbbb' (tall letters)")
print("  Box 3: 'aabb' (mixed - baseline should NOT jump)")
print("\nType more characters to test. Press ESC to exit.\n")

local running = true
local ev = ffi.new("SDL_Event")

while running do
    while sdl.SDL_PollEvent(ev) do
        local result = gui.gui_process_events(ctx, ev)
        if result == sdlm.SDL_APP_SUCCESS then
            running = false
            break
        end
    end

    if not running then break end

    gui.gui_begin(renderer[0], texture, ctx)

    -- Draw labels
    gui.gui_label(ctx, 20, 50, "Short chars:")
    gui.gui_editbox(ctx, 150, 40, 200, es1)

    gui.gui_label(ctx, 20, 100, "Tall chars:")
    gui.gui_editbox(ctx, 150, 90, 200, es2)

    gui.gui_label(ctx, 20, 150, "Mixed (test):")
    gui.gui_editbox(ctx, 150, 140, 200, es3)

    gui.gui_label(ctx, 20, 200, "Type in the boxes above to test baseline consistency.")
    gui.gui_label(ctx, 20, 230, "The text should not jump up/down as you type different letters.")

    gui.gui_end(ctx)

    sdl.SDL_Delay(16) -- ~60fps
end

-- Cleanup
sdl.SDL_DestroyTexture(texture)
sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()

print("Test complete. If the baseline stayed consistent, the fix works!")
