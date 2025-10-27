#!/usr/bin/env luajit
-- Diagnose SDL_KeyboardEvent struct layout by dumping raw bytes
local ffi = require("ffi")
local sdlm = require("ffi_sdl3")
local sdl = sdlm.sdl

print("=== SDL_KeyboardEvent Structure Diagnostic ===\n")

if not sdl.SDL_Init(sdlm.SDL_INIT_VIDEO) then
    io.stderr:write("ERROR: SDL_Init failed\n")
    os.exit(1)
end

local window = ffi.new("SDL_Window*[1]")
local renderer = ffi.new("SDL_Renderer*[1]")
if not sdl.SDL_CreateWindowAndRenderer("Keyboard Test", 400, 300, 0, window, renderer) then
    io.stderr:write("ERROR: CreateWindowAndRenderer failed\n")
    sdl.SDL_Quit()
    os.exit(1)
end

sdl.SDL_RaiseWindow(window[0])

print("Press 'q' key to see the raw event structure...\n")

local ev = ffi.new("SDL_Event")
local found = false

for i = 1, 500 do
    if sdl.SDL_PollEvent(ev) then
        if ev.type == sdlm.SDL_EVENT_KEY_DOWN then
            print("KEY_DOWN event received!")
            print(string.format("  type      = 0x%08x", ev.type))
            print(string.format("  key.key   = 0x%08x (%d)", ev.key.key, ev.key.key))
            print(string.format("  key.mod   = 0x%04x (%d)", ev.key.mod, ev.key.mod))
            print(string.format("  key.scancode = 0x%08x (%d)", ev.key.scancode, ev.key.scancode))
            print(string.format("  key.windowID = 0x%08x", ev.key.windowID))
            print(string.format("  key.repeat = %d", ev.key['repeat']))

            -- Dump raw bytes
            local ptr = ffi.cast("uint8_t*", ev)
            print("\nRaw bytes (first 64):")
            for j = 0, 63 do
                io.write(string.format("%02x ", ptr[j]))
                if (j + 1) % 16 == 0 then io.write("\n") end
            end
            print("")

            found = true
            break
        end
    end
    sdl.SDL_Delay(10)
end

if not found then
    print("No KEY_DOWN event received within timeout")
end

sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()

print("\n=== Done ===")
