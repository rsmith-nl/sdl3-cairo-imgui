#!/usr/bin/env luajit
-- Minimal test to see if SDL keyboard events are arriving at all
local ffi = require("ffi")
local sdlm = require("ffi_sdl3")
local sdl = sdlm.sdl

io.stdout:setvbuf("no")
io.stderr:setvbuf("no")

print("=== SDL Keyboard Event Test ===")
print("Press keys - they should be logged below")
print("Press ESC to quit\n")

if not sdl.SDL_Init(sdlm.SDL_INIT_VIDEO) then
    print("ERROR: SDL_Init failed")
    os.exit(1)
end

local window = ffi.new("SDL_Window*[1]")
local renderer = ffi.new("SDL_Renderer*[1]")
if not sdl.SDL_CreateWindowAndRenderer("Keyboard Test", 400, 300, 0, window, renderer) then
    print("ERROR: CreateWindowAndRenderer failed")
    sdl.SDL_Quit(); os.exit(1)
end

-- Drain startup events
sdl.SDL_Delay(100)
local event = ffi.new("SDL_Event")
local drained = 0
while sdl.SDL_PollEvent(event) do
    drained = drained + 1
    if drained > 5000 then break end
end
print(string.format("Drained %d startup events\n", drained))

local running = true
local frame = 0

-- Push a synthetic 'q' KEY_DOWN event to verify mapping works even without user input
do
    local ev = ffi.new("SDL_Event")
    ev.type = sdlm.SDL_EVENT_KEY_DOWN
    ev.key.key = string.byte('q')
    ev.key.mod = 0
    sdl.SDL_PushEvent(ev)
end

while running do
    -- Process events
    local processed = 0
    while sdl.SDL_PollEvent(event) do
        if event.type == sdlm.SDL_EVENT_QUIT then
            print("→ QUIT event")
            running = false
            break
        elseif event.type == sdlm.SDL_EVENT_KEY_DOWN then
            print(string.format("→ KEY_DOWN: key=%d (0x%x) scancode=%d mod=0x%x",
                event.key.key, event.key.key, event.key.scancode, event.key.mod))
            if event.key.key == sdlm.SDLK_ESCAPE then
                print("  (ESC pressed - quitting)")
                running = false
                break
            end
        elseif event.type == sdlm.SDL_EVENT_KEY_UP then
            print(string.format("→ KEY_UP: key=%d (0x%x) scancode=%d mod=0x%x",
                event.key.key, event.key.key, event.key.scancode, event.key.mod))
        elseif event.type == sdlm.SDL_EVENT_MOUSE_BUTTON_DOWN then
            print(string.format("→ MOUSE_DOWN: x=%.0f y=%.0f", event.button.x, event.button.y))
        elseif event.type == sdlm.SDL_EVENT_MOUSE_BUTTON_UP then
            print(string.format("→ MOUSE_UP: x=%.0f y=%.0f", event.button.x, event.button.y))
        end

        processed = processed + 1
        if processed >= 200 then break end
    end
    if processed >= 200 then sdl.SDL_Delay(1) end

    if not running then break end

    -- Just delay to keep window alive
    frame = frame + 1
    sdl.SDL_Delay(33) -- ~30 fps
end

sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()

print(string.format("\n=== Test ended after %d frames ===", frame))
