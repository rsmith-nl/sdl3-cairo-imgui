#!/usr/bin/env luajit
-- Debug what modifiers are active when typing
local ffi = require("ffi")
local bit = require("bit")
local sdlm = require("ffi_sdl3")
local gui = require("cairo_imgui")
local sdl = sdlm.sdl

print("=== Editbox Modifier Debug ===")
print("Type a few letters and we'll show the modifier state\n")

-- Setup SDL
if not sdl.SDL_Init(sdlm.SDL_INIT_VIDEO) then
    io.stderr:write("ERROR: SDL_Init failed\n")
    os.exit(1)
end

local window = ffi.new("SDL_Window*[1]")
local renderer = ffi.new("SDL_Renderer*[1]")
if not sdl.SDL_CreateWindowAndRenderer("Modifier Debug", 400, 300, 0, window, renderer) then
    io.stderr:write("ERROR: CreateWindowAndRenderer failed\n")
    sdl.SDL_Quit(); os.exit(1)
end

sdl.SDL_RaiseWindow(window[0])

local texture = sdl.SDL_CreateTexture(renderer[0], sdlm.SDL_PIXELFORMAT_ARGB8888,
    sdlm.SDL_TEXTUREACCESS_STREAMING, 400, 300)

-- GUI context
local ctx = gui.gui_context_new()
gui.gui_theme_dark(ctx)

-- Editbox state
local es = gui.gui_editstate_new()

-- Click to focus
local function feed_click(x, y)
    local ev = ffi.new("SDL_Event")
    ev.type = sdlm.SDL_EVENT_MOUSE_MOTION
    ev.motion.x = x; ev.motion.y = y
    gui.gui_process_events(ctx, ev)

    ev.type = sdlm.SDL_EVENT_MOUSE_BUTTON_DOWN
    ev.button.x = x; ev.button.y = y
    gui.gui_process_events(ctx, ev)

    ev.type = sdlm.SDL_EVENT_MOUSE_BUTTON_UP
    ev.button.x = x; ev.button.y = y
    gui.gui_process_events(ctx, ev)
end

feed_click(200, 100)
gui.gui_begin(renderer[0], texture, ctx)
gui.gui_editbox(ctx, 150, 90, 100, es)
gui.gui_end(ctx)

print("Editbox focused. Type some letters (or press Esc to quit)...\n")

local ev = ffi.new("SDL_Event")
local count = 0

while count < 50 do
    if sdl.SDL_WaitEventTimeout(ev, 100) then
        if ev.type == sdlm.SDL_EVENT_QUIT then
            break
        elseif ev.type == sdlm.SDL_EVENT_KEY_UP then
            local key = ev.key.key
            local mod = ev.key.mod

            if key == sdlm.SDLK_ESCAPE then
                break
            end

            if key >= 0x20 and key <= 0x7e then
                local char = string.char(key)
                local has_shift = bit.band(mod, sdlm.SDL_KMOD_LSHIFT) ~= 0 or bit.band(mod, sdlm.SDL_KMOD_RSHIFT) ~= 0
                local has_caps = bit.band(mod, sdlm.SDL_KMOD_CAPS) ~= 0

                print(string.format("Key '%s' (0x%02x): mod=0x%04x SHIFT=%s CAPS=%s",
                    char, key, mod, has_shift and "YES" or "no", has_caps and "YES" or "no"))

                count = count + 1
            end

            gui.gui_process_events(ctx, ev)
            gui.gui_begin(renderer[0], texture, ctx)
            gui.gui_editbox(ctx, 150, 90, 100, es)
            gui.gui_end(ctx)
        else
            gui.gui_process_events(ctx, ev)
            gui.gui_begin(renderer[0], texture, ctx)
            gui.gui_editbox(ctx, 150, 90, 100, es)
            gui.gui_end(ctx)
        end
    end
end

local text = ffi.string(es.data, tonumber(es.used) or 0)
print("\nFinal buffer: '" .. text .. "'")

-- Cleanup
sdl.SDL_DestroyTexture(texture)
sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()

print("\n=== Done ===")
