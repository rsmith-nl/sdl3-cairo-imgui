-- ffi_sdl3.lua
-- LuaJIT FFI bindings for SDL3
-- This is free and unencumbered software released into the public domain.

local ffi = require("ffi")

-- SDL3 type definitions and function declarations
ffi.cdef [[
// Basic types
typedef int32_t SDL_Keycode;
typedef uint16_t SDL_Keymod;
typedef uint32_t SDL_WindowFlags;
typedef int SDL_bool;
typedef enum { SDL_FALSE = 0, SDL_TRUE = 1 } SDL_BoolEnum;

// Opaque pointers
typedef struct SDL_Window SDL_Window;
typedef struct SDL_Renderer SDL_Renderer;
typedef struct SDL_Texture SDL_Texture;

// Rectangle structure
typedef struct SDL_Rect {
    int x, y;
    int w, h;
} SDL_Rect;

// Pixel format
typedef enum {
    SDL_PIXELFORMAT_ARGB8888 = 0x16362004
} SDL_PixelFormat;

// Texture access
typedef enum {
    SDL_TEXTUREACCESS_STATIC = 0,
    SDL_TEXTUREACCESS_STREAMING = 1,
    SDL_TEXTUREACCESS_TARGET = 2
} SDL_TextureAccess;

// Init flags
typedef enum {
    SDL_INIT_VIDEO = 0x00000020
} SDL_InitFlags;

// VSync modes
typedef enum {
    SDL_RENDERER_VSYNC_DISABLED = 0,
    SDL_RENDERER_VSYNC_ADAPTIVE = -1
} SDL_RendererVSync;

// Blend modes
typedef enum {
    SDL_BLENDMODE_NONE = 0x00000000,
    SDL_BLENDMODE_BLEND = 0x00000001,
    SDL_BLENDMODE_ADD = 0x00000002,
    SDL_BLENDMODE_MOD = 0x00000004,
    SDL_BLENDMODE_MUL = 0x00000008
} SDL_BlendMode;

// App results
typedef enum {
    SDL_APP_CONTINUE = 0,
    SDL_APP_SUCCESS = 1,
    SDL_APP_FAILURE = 2
} SDL_AppResult;

// Event types
typedef enum {
    SDL_EVENT_QUIT = 0x100,
    SDL_EVENT_KEY_DOWN = 0x300,
    SDL_EVENT_KEY_UP = 0x301,
    SDL_EVENT_MOUSE_MOTION = 0x400,
    SDL_EVENT_MOUSE_BUTTON_DOWN = 0x401,
    SDL_EVENT_MOUSE_BUTTON_UP = 0x402,
    SDL_EVENT_WINDOW_RESIZED = 0x203
} SDL_EventType;

// Keyboard key codes
static const SDL_Keycode SDLK_ESCAPE = 27;
static const SDL_Keycode SDLK_RETURN = 13;
static const SDL_Keycode SDLK_SPACE = 32;
static const SDL_Keycode SDLK_TAB = 9;
static const SDL_Keycode SDLK_BACKSPACE = 8;
static const SDL_Keycode SDLK_DELETE = 127;
static const SDL_Keycode SDLK_LEFT = 0x40000050;
static const SDL_Keycode SDLK_RIGHT = 0x4000004F;
static const SDL_Keycode SDLK_UP = 0x40000052;
static const SDL_Keycode SDLK_DOWN = 0x40000051;
static const SDL_Keycode SDLK_HOME = 0x4000004A;
static const SDL_Keycode SDLK_END = 0x4000004D;

// Keyboard modifiers
static const SDL_Keymod SDL_KMOD_LSHIFT = 0x0001;
static const SDL_Keymod SDL_KMOD_RSHIFT = 0x0002;
static const SDL_Keymod SDL_KMOD_CAPS = 0x2000;

// Event structures
typedef struct {
    uint32_t type;          // SDL_EventType
    uint32_t reserved;
    uint64_t timestamp;     // nanoseconds
    uint32_t windowID;      // SDL_WindowID
    uint32_t which;         // SDL_KeyboardID (the keyboard instance id)
    int32_t scancode;       // SDL_Scancode
    int32_t key;            // SDL_Keycode
    uint16_t mod;           // SDL_Keymod
    uint16_t raw;           // platform dependent scancode
    uint8_t down;           // bool: true if pressed
    uint8_t repeat;         // bool: true if key repeat
    uint16_t padding;       // alignment
} SDL_KeyboardEvent;

typedef struct {
    uint32_t type;
    uint32_t reserved;
    uint64_t timestamp;
    uint32_t windowID;
    float x;
    float y;
    float xrel;
    float yrel;
} SDL_MouseMotionEvent;

typedef struct {
    uint32_t type;
    uint32_t reserved;
    uint64_t timestamp;
    uint32_t windowID;
    uint32_t which;
    uint8_t button;
    uint8_t down;
    uint8_t clicks;
    uint8_t padding;
    float x;
    float y;
} SDL_MouseButtonEvent;

typedef struct {
    uint32_t type;
    uint32_t reserved;
    uint64_t timestamp;
    uint32_t windowID;
    int32_t data1;
    int32_t data2;
} SDL_WindowEvent;

typedef union SDL_Event {
    uint32_t type;
    SDL_KeyboardEvent key;
    SDL_MouseMotionEvent motion;
    SDL_MouseButtonEvent button;
    SDL_WindowEvent window;
    uint8_t padding[128];
} SDL_Event;

// SDL3 functions
SDL_bool SDL_Init(uint32_t flags);
void SDL_Quit(void);
const char* SDL_GetError(void);
void SDL_Log(const char* fmt, ...);
SDL_bool SDL_SetHint(const char* name, const char* value);

SDL_bool SDL_CreateWindowAndRenderer(
    const char* title,
    int width,
    int height,
    SDL_WindowFlags window_flags,
    SDL_Window** window,
    SDL_Renderer** renderer
);

void SDL_DestroyWindow(SDL_Window* window);
void SDL_DestroyRenderer(SDL_Renderer* renderer);
void SDL_DestroyTexture(SDL_Texture* texture);
void SDL_RaiseWindow(SDL_Window* window);

SDL_bool SDL_GetWindowSize(SDL_Window* window, int* w, int* h);
SDL_Window* SDL_GetRenderWindow(SDL_Renderer* renderer);

SDL_Texture* SDL_CreateTexture(
    SDL_Renderer* renderer,
    SDL_PixelFormat format,
    SDL_TextureAccess access,
    int w,
    int h
);

SDL_bool SDL_LockTexture(SDL_Texture* texture, const SDL_Rect* rect, void** pixels, int* pitch);
void SDL_UnlockTexture(SDL_Texture* texture);

SDL_bool SDL_GetCurrentRenderOutputSize(SDL_Renderer* renderer, int* w, int* h);
SDL_bool SDL_RenderTexture(SDL_Renderer* renderer, SDL_Texture* texture, const SDL_Rect* srcrect, const SDL_Rect* dstrect);
SDL_bool SDL_RenderPresent(SDL_Renderer* renderer);
SDL_bool SDL_SetRenderVSync(SDL_Renderer* renderer, int vsync);
SDL_bool SDL_SetTextureBlendMode(SDL_Texture* texture, SDL_BlendMode blendMode);

SDL_bool SDL_PollEvent(SDL_Event* event);
SDL_bool SDL_WaitEvent(SDL_Event* event);
SDL_bool SDL_WaitEventTimeout(SDL_Event* event, int timeoutMS);
int SDL_PushEvent(SDL_Event* event);
void SDL_Delay(uint32_t ms);
uint32_t SDL_GetTicks(void);
]]

-- Hint constants (as Lua strings)
local SDL_HINT_MAIN_CALLBACK_RATE = "SDL_MAIN_CALLBACK_RATE"

-- Load SDL3 library
local sdl = ffi.load("SDL3")

-- Export module
return {
    sdl = sdl,
    ffi = ffi,

    -- Constants
    SDL_INIT_VIDEO = ffi.C.SDL_INIT_VIDEO,
    SDL_PIXELFORMAT_ARGB8888 = ffi.C.SDL_PIXELFORMAT_ARGB8888,
    SDL_TEXTUREACCESS_STREAMING = ffi.C.SDL_TEXTUREACCESS_STREAMING,
    SDL_RENDERER_VSYNC_ADAPTIVE = ffi.C.SDL_RENDERER_VSYNC_ADAPTIVE,

    -- Blend modes
    SDL_BLENDMODE_NONE = ffi.C.SDL_BLENDMODE_NONE,
    SDL_BLENDMODE_BLEND = ffi.C.SDL_BLENDMODE_BLEND,
    SDL_BLENDMODE_ADD = ffi.C.SDL_BLENDMODE_ADD,
    SDL_BLENDMODE_MOD = ffi.C.SDL_BLENDMODE_MOD,
    SDL_BLENDMODE_MUL = ffi.C.SDL_BLENDMODE_MUL,

    -- Event types
    SDL_EVENT_QUIT = ffi.C.SDL_EVENT_QUIT,
    SDL_EVENT_KEY_UP = ffi.C.SDL_EVENT_KEY_UP,
    SDL_EVENT_KEY_DOWN = ffi.C.SDL_EVENT_KEY_DOWN,
    SDL_EVENT_MOUSE_MOTION = ffi.C.SDL_EVENT_MOUSE_MOTION,
    SDL_EVENT_MOUSE_BUTTON_DOWN = ffi.C.SDL_EVENT_MOUSE_BUTTON_DOWN,
    SDL_EVENT_MOUSE_BUTTON_UP = ffi.C.SDL_EVENT_MOUSE_BUTTON_UP,
    SDL_EVENT_WINDOW_RESIZED = ffi.C.SDL_EVENT_WINDOW_RESIZED,

    -- Key codes
    SDLK_ESCAPE = ffi.C.SDLK_ESCAPE,
    SDLK_RETURN = ffi.C.SDLK_RETURN,
    SDLK_TAB = ffi.C.SDLK_TAB,
    SDLK_SPACE = ffi.C.SDLK_SPACE,
    SDLK_BACKSPACE = ffi.C.SDLK_BACKSPACE,
    SDLK_DELETE = ffi.C.SDLK_DELETE,
    SDLK_LEFT = ffi.C.SDLK_LEFT,
    SDLK_RIGHT = ffi.C.SDLK_RIGHT,
    SDLK_UP = ffi.C.SDLK_UP,
    SDLK_DOWN = ffi.C.SDLK_DOWN,
    SDLK_HOME = ffi.C.SDLK_HOME,
    SDLK_END = ffi.C.SDLK_END,

    -- Key modifiers
    SDL_KMOD_LSHIFT = ffi.C.SDL_KMOD_LSHIFT,
    SDL_KMOD_RSHIFT = ffi.C.SDL_KMOD_RSHIFT,
    SDL_KMOD_CAPS = ffi.C.SDL_KMOD_CAPS,

    -- App results
    SDL_APP_CONTINUE = ffi.C.SDL_APP_CONTINUE,
    SDL_APP_SUCCESS = ffi.C.SDL_APP_SUCCESS,
    SDL_APP_FAILURE = ffi.C.SDL_APP_FAILURE,

    -- Hint names
    SDL_HINT_MAIN_CALLBACK_RATE = SDL_HINT_MAIN_CALLBACK_RATE,

    -- Time
    SDL_GetTicks = sdl.SDL_GetTicks,
}
