#!/usr/bin/env luajit
-- Interactive demo with click event logging to diagnose button activation
local ffi = require("ffi")
local sdl_module = require("ffi_sdl3")
local gui = require("cairo_imgui")

local sdl = sdl_module.sdl

-- Initialize SDL
if not sdl.SDL_Init(sdl_module.SDL_INIT_VIDEO) then
    print("Couldn't initialize SDL: " .. ffi.string(sdl.SDL_GetError()))
    os.exit(1)
end

local window = ffi.new("SDL_Window*[1]")
local renderer = ffi.new("SDL_Renderer*[1]")
local w, h = 400, 300

if not sdl.SDL_CreateWindowAndRenderer("Button Debug Demo", w, h, 0, window, renderer) then
    print("Couldn't create window and renderer: " .. ffi.string(sdl.SDL_GetError()))
    os.exit(1)
end

local texture = sdl.SDL_CreateTexture(renderer[0], sdl_module.SDL_PIXELFORMAT_ARGB8888,
    sdl_module.SDL_TEXTUREACCESS_STREAMING, w, h)
sdl.SDL_SetTextureBlendMode(texture, sdl_module.SDL_BLENDMODE_NONE)

-- GUI context
local ctx = gui.gui_context_new()
gui.gui_theme_dark(ctx)

local count = 0
local running = true
local event = ffi.new("SDL_Event")

print("=== Click events and button state logging ===")
print("Click anywhere in the window to see event details")
print("Press 'q' to quit\n")

-- Drain startup events
sdl.SDL_Delay(100)
local drained = 0
while sdl.SDL_PollEvent(event) do
    drained = drained + 1
    if drained > 5000 then break end
end

while running do
    -- Process events with logging
    local processed = 0
    while sdl.SDL_PollEvent(event) do
        if event.type == sdl_module.SDL_EVENT_MOUSE_BUTTON_DOWN then
            print(string.format("→ MOUSE_DOWN x=%.0f y=%.0f", event.button.x, event.button.y))
        elseif event.type == sdl_module.SDL_EVENT_MOUSE_BUTTON_UP then
            print(string.format("→ MOUSE_UP x=%.0f y=%.0f", event.button.x, event.button.y))
        elseif event.type == sdl_module.SDL_EVENT_MOUSE_MOTION then
            -- Don't spam motion
        end

        local result = gui.gui_process_events(ctx, event)
        if result == sdl_module.SDL_APP_SUCCESS then
            running = false
            break
        end

        processed = processed + 1
        if processed >= 200 then break end
    end
    if processed >= 200 then sdl.SDL_Delay(1) end

    if not running then break end

    -- Draw frame
    gui.gui_begin(renderer[0], texture, ctx)

    -- Test button at (10,10)
    print(string.format("  [frame] button_pressed=%s button_released=%s mouse=(%d,%d)",
        tostring(ctx.button_pressed), tostring(ctx.button_released), ctx.mouse_x, ctx.mouse_y))

    if gui.gui_button(ctx, 10, 10, "Test") then
        count = count + 1
        print(string.format("★ BUTTON ACTIVATED! Count=%d", count))
    end
    gui.gui_label(ctx, 75, 17, string.format("Pressed %d times", count))

    if gui.gui_button(ctx, 10, 260, "Close") then
        print("★ CLOSE BUTTON ACTIVATED")
        running = false
    end

    gui.gui_end(ctx)

    sdl.SDL_Delay(33) -- ~30 fps
end

sdl.SDL_DestroyTexture(texture)
sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()
print("\n=== Demo ended ===")
