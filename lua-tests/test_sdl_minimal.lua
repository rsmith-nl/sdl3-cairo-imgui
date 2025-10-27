#!/usr/bin/env luajit
-- Minimal SDL3 test: create window, render 10 frames, auto-exit
-- Usage: luajit test_sdl_minimal.lua

local ffi = require("ffi")
-- Unbuffer stdout so frame logs show immediately
io.stdout:setvbuf("no")

-- Minimal SDL3 FFI declarations
ffi.cdef [[
typedef struct SDL_Window SDL_Window;
typedef struct SDL_Renderer SDL_Renderer;
typedef int SDL_bool;

SDL_bool SDL_Init(uint32_t flags);
void SDL_Quit(void);
const char* SDL_GetError(void);

SDL_bool SDL_CreateWindowAndRenderer(
    const char* title, int width, int height,
    uint32_t window_flags,
    SDL_Window** window, SDL_Renderer** renderer
);

void SDL_DestroyWindow(SDL_Window* window);
void SDL_DestroyRenderer(SDL_Renderer* renderer);

SDL_bool SDL_SetRenderDrawColor(SDL_Renderer* renderer, uint8_t r, uint8_t g, uint8_t b, uint8_t a);
SDL_bool SDL_RenderClear(SDL_Renderer* renderer);
SDL_bool SDL_RenderPresent(SDL_Renderer* renderer);
void SDL_Delay(uint32_t ms);

typedef union SDL_Event {
    uint32_t type;
    uint8_t padding[128];
} SDL_Event;

SDL_bool SDL_PollEvent(SDL_Event* event);
]]

-- Constants
local SDL_INIT_VIDEO = 0x00000020
local SDL_EVENT_QUIT = 0x100

-- Load SDL3
local sdl = ffi.load("SDL3")

print("=== Minimal SDL3 Test ===")

-- Initialize SDL
if not sdl.SDL_Init(SDL_INIT_VIDEO) then
    print("ERROR: SDL_Init failed: " .. ffi.string(sdl.SDL_GetError()))
    os.exit(1)
end
print("✓ SDL initialized")

-- Create window and renderer
local window = ffi.new("SDL_Window*[1]")
local renderer = ffi.new("SDL_Renderer*[1]")

if not sdl.SDL_CreateWindowAndRenderer("SDL3 Minimal Test", 400, 300, 0, window, renderer) then
    print("ERROR: Window creation failed: " .. ffi.string(sdl.SDL_GetError()))
    sdl.SDL_Quit()
    os.exit(1)
end
print("✓ Window and renderer created")

-- Drain some startup events to avoid immediate QUIT/flood
sdl.SDL_Delay(100)
local event = ffi.new("SDL_Event")
do
    local drained = 0
    while sdl.SDL_PollEvent(event) do
        drained = drained + 1
        if drained > 5000 then break end
    end
    print(string.format("✓ Startup events drained (%d)", drained))
end

-- Render 10 frames
local frame_count = 0
local target_frames = 10
local running = true

print("Rendering frames...")
while running and frame_count < target_frames do
    -- Process events
    do
        local processed = 0
        while sdl.SDL_PollEvent(event) do
            if event.type == SDL_EVENT_QUIT then
                running = false
                break
            end
            processed = processed + 1
            if processed >= 200 then
                -- avoid being starved by event storms
                break
            end
        end
        if processed >= 200 then sdl.SDL_Delay(1) end
    end

    if not running then break end

    -- Render: alternate colors
    local color = (frame_count % 2 == 0) and 50 or 100
    sdl.SDL_SetRenderDrawColor(renderer[0], color, color, color, 255)
    sdl.SDL_RenderClear(renderer[0])
    sdl.SDL_RenderPresent(renderer[0])

    frame_count = frame_count + 1
    print(string.format("  Frame %d/%d", frame_count, target_frames))

    sdl.SDL_Delay(100) -- 10 fps
end

-- Cleanup
sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()

print(string.format("✓ Completed: rendered %d frames", frame_count))
print("=== Test PASSED ===")
