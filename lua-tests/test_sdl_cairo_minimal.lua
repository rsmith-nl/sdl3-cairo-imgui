#!/usr/bin/env luajit
-- Minimal SDL3 + Cairo test: draw with Cairo into an SDL texture and present
-- Usage: luajit test_sdl_cairo_minimal.lua

local ffi = require("ffi")
-- Unbuffer stdout so frame logs show immediately
io.stdout:setvbuf("no")

-- SDL3 FFI declarations (subset)
ffi.cdef [[
typedef struct SDL_Window SDL_Window;
typedef struct SDL_Renderer SDL_Renderer;
typedef struct SDL_Texture SDL_Texture;
typedef int SDL_bool;

typedef struct SDL_Rect { int x, y, w, h; } SDL_Rect;

typedef enum {
    SDL_PIXELFORMAT_ARGB8888 = 0x16362004
} SDL_PixelFormat;

typedef enum {
    SDL_TEXTUREACCESS_STREAMING = 1
} SDL_TextureAccess;

typedef enum {
    SDL_BLENDMODE_NONE = 0x00000000
} SDL_BlendMode;

SDL_bool SDL_Init(uint32_t flags);
void SDL_Quit(void);
const char* SDL_GetError(void);

SDL_bool SDL_CreateWindowAndRenderer(const char* title, int width, int height, uint32_t window_flags, SDL_Window** window, SDL_Renderer** renderer);
void SDL_DestroyWindow(SDL_Window* window);
void SDL_DestroyRenderer(SDL_Renderer* renderer);
void SDL_DestroyTexture(SDL_Texture* texture);

SDL_Texture* SDL_CreateTexture(SDL_Renderer* renderer, SDL_PixelFormat format, SDL_TextureAccess access, int w, int h);
SDL_bool SDL_SetTextureBlendMode(SDL_Texture* texture, SDL_BlendMode blendMode);

SDL_bool SDL_LockTexture(SDL_Texture* texture, const SDL_Rect* rect, void** pixels, int* pitch);
void SDL_UnlockTexture(SDL_Texture* texture);

SDL_bool SDL_RenderTexture(SDL_Renderer* renderer, SDL_Texture* texture, const SDL_Rect* srcrect, const SDL_Rect* dstrect);
SDL_bool SDL_RenderPresent(SDL_Renderer* renderer);
SDL_bool SDL_SetRenderDrawColor(SDL_Renderer* renderer, uint8_t r, uint8_t g, uint8_t b, uint8_t a);
SDL_bool SDL_RenderClear(SDL_Renderer* renderer);

void SDL_Delay(uint32_t ms);

typedef union SDL_Event { uint32_t type; uint8_t padding[128]; } SDL_Event;
SDL_bool SDL_PollEvent(SDL_Event* event);
]]

local SDL_INIT_VIDEO = 0x00000020
local SDL_EVENT_QUIT = 0x100

-- Cairo FFI declarations (subset)
ffi.cdef [[
typedef struct _cairo cairo_t;
typedef struct _cairo_surface cairo_surface_t;

typedef enum { CAIRO_FORMAT_ARGB32 = 0 } cairo_format_t;

typedef struct { double x_bearing, y_bearing, width, height, x_advance, y_advance; } cairo_text_extents_t;

cairo_surface_t* cairo_image_surface_create_for_data(unsigned char* data, cairo_format_t format, int width, int height, int stride);
void cairo_surface_flush(cairo_surface_t* surface);
void cairo_surface_destroy(cairo_surface_t* surface);

cairo_t* cairo_create(cairo_surface_t* target);
void cairo_destroy(cairo_t* cr);

void cairo_set_source_rgb(cairo_t* cr, double r, double g, double b);
void cairo_paint(cairo_t* cr);
void cairo_new_path(cairo_t* cr);
void cairo_rectangle(cairo_t* cr, double x, double y, double w, double h);
void cairo_fill(cairo_t* cr);
void cairo_set_font_size(cairo_t* cr, double size);
void cairo_move_to(cairo_t* cr, double x, double y);
void cairo_show_text(cairo_t* cr, const char* utf8);
void cairo_text_extents(cairo_t* cr, const char* utf8, cairo_text_extents_t* extents);
]]

local sdl = ffi.load("SDL3")
local cairo = ffi.load("cairo")

print("=== Minimal SDL3 + Cairo Test ===")

-- Initialize
if not sdl.SDL_Init(SDL_INIT_VIDEO) then
    print("ERROR: SDL_Init failed: " .. ffi.string(sdl.SDL_GetError()))
    os.exit(1)
end

local window = ffi.new("SDL_Window*[1]")
local renderer = ffi.new("SDL_Renderer*[1]")
local w, h = 400, 300
if not sdl.SDL_CreateWindowAndRenderer("SDL+Cairo Minimal", w, h, 0, window, renderer) then
    print("ERROR: SDL_CreateWindowAndRenderer failed: " .. ffi.string(sdl.SDL_GetError()))
    sdl.SDL_Quit(); os.exit(1)
end
print("✓ Window & renderer")

local texture = sdl.SDL_CreateTexture(renderer[0], ffi.C.SDL_PIXELFORMAT_ARGB8888, ffi.C.SDL_TEXTUREACCESS_STREAMING, w,
    h)
if texture == nil then
    print("ERROR: SDL_CreateTexture failed: " .. ffi.string(sdl.SDL_GetError()))
    sdl.SDL_DestroyWindow(window[0]); sdl.SDL_DestroyRenderer(renderer[0]); sdl.SDL_Quit(); os.exit(1)
end
-- Avoid blending surprises
sdl.SDL_SetTextureBlendMode(texture, ffi.C.SDL_BLENDMODE_NONE)

-- Draw a few frames
local frames = 0
local target = 10
local event = ffi.new("SDL_Event")

-- Drain some startup events to avoid immediate QUIT/flood
sdl.SDL_Delay(100)
do
    local drained = 0
    while sdl.SDL_PollEvent(event) do
        drained = drained + 1
        if drained > 5000 then break end
    end
    print(string.format("✓ Startup events drained (%d)", drained))
end

while frames < target do
    -- process quit with cap to avoid starvation during event storms
    do
        local processed = 0
        while sdl.SDL_PollEvent(event) do
            if event.type == SDL_EVENT_QUIT then
                frames = target; break
            end
            processed = processed + 1
            if processed >= 200 then
                break
            end
        end
        if processed >= 200 then sdl.SDL_Delay(1) end
    end

    -- Lock texture and create cairo surface
    local pixels = ffi.new("void*[1]")
    local pitch = ffi.new("int[1]")
    sdl.SDL_LockTexture(texture, nil, pixels, pitch)

    local surface = cairo.cairo_image_surface_create_for_data(ffi.cast("unsigned char*", pixels[0]),
        ffi.C.CAIRO_FORMAT_ARGB32, w, h, pitch[0])
    local cr = cairo.cairo_create(surface)

    -- Background
    cairo.cairo_set_source_rgb(cr, 0.1, 0.12, 0.14)
    cairo.cairo_paint(cr)

    -- Moving bar
    local x = 20 + (frames * 15) % (w - 40)
    cairo.cairo_new_path(cr)
    cairo.cairo_set_source_rgb(cr, 0.15, 0.55, 0.82)
    cairo.cairo_rectangle(cr, x, 40, 30, 30)
    cairo.cairo_fill(cr)

    -- Label
    cairo.cairo_set_source_rgb(cr, 0.9, 0.9, 0.9)
    cairo.cairo_set_font_size(cr, 16)
    cairo.cairo_move_to(cr, 20, h - 20)
    cairo.cairo_show_text(cr, string.format("frame %d/%d", frames + 1, target))

    cairo.cairo_surface_flush(surface)
    cairo.cairo_destroy(cr)
    cairo.cairo_surface_destroy(surface)

    sdl.SDL_UnlockTexture(texture)

    -- Present
    sdl.SDL_SetRenderDrawColor(renderer[0], 0, 0, 0, 255)
    sdl.SDL_RenderClear(renderer[0])
    sdl.SDL_RenderTexture(renderer[0], texture, nil, nil)
    sdl.SDL_RenderPresent(renderer[0])

    frames = frames + 1
    print(string.format("  Frame %d/%d", frames, target))
    sdl.SDL_Delay(100)
end

sdl.SDL_DestroyTexture(texture)
sdl.SDL_DestroyRenderer(renderer[0])
sdl.SDL_DestroyWindow(window[0])
sdl.SDL_Quit()
print("✓ Completed SDL+Cairo minimal test")
