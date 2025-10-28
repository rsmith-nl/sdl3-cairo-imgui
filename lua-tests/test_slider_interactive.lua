#!/usr/bin/env luajit
-- Interactive test: drag the slider knob
-- ESC to quit. Use LEFT/RIGHT to adjust when focused.

local ffi = require("ffi")
local sdlm = require("ffi_sdl3")
local gui = require("cairo_imgui")
local cairo = require("ffi_cairo").cairo
local app_loop = require("gui_app_loop")
local sdl = sdlm.sdl

-- Optional pacing/auto-exit
local TARGET_FPS = tonumber(os.getenv("IMGUI_FPS") or "") or 60
if TARGET_FPS < 1 then TARGET_FPS = 60 end
local FRAME_DELAY_MS = math.floor(1000 / TARGET_FPS)
local RUN_SECONDS = tonumber(os.getenv("IMGUI_RUN_SECONDS") or "") or nil

-- App state
local state = {
    window = nil,
    renderer = nil,
    texture = nil,
    ctx = nil,
    running = true,
}

local function app_init()
    state.ctx = gui.gui_context_new()
    gui.gui_theme_dark(state.ctx)

    -- Match demo.lua pacing hint to reduce event flooding
    sdl.SDL_SetHint(sdlm.SDL_HINT_MAIN_CALLBACK_RATE, "10")

    if not sdl.SDL_Init(sdlm.SDL_INIT_VIDEO) then
        io.stderr:write("[init] SDL_Init failed: " .. ffi.string(sdl.SDL_GetError()) .. "\n")
        return false
    end

    local window_ptr = ffi.new("SDL_Window*[1]")
    local renderer_ptr = ffi.new("SDL_Renderer*[1]")
    if not sdl.SDL_CreateWindowAndRenderer("Slider Interactive Test", 420, 160, 0, window_ptr, renderer_ptr) then
        io.stderr:write("[init] CreateWindowAndRenderer failed: " .. ffi.string(sdl.SDL_GetError()) .. "\n")
        return false
    end
    state.window = window_ptr[0]
    state.renderer = renderer_ptr[0]

    -- Texture: match initial window size
    state.texture = sdl.SDL_CreateTexture(state.renderer, sdlm.SDL_PIXELFORMAT_ARGB8888, sdlm
        .SDL_TEXTUREACCESS_STREAMING, 420, 160)
    sdl.SDL_SetTextureBlendMode(state.texture, sdlm.SDL_BLENDMODE_NONE)
    sdl.SDL_SetRenderVSync(state.renderer, sdlm.SDL_RENDERER_VSYNC_ADAPTIVE)

    sdl.SDL_RaiseWindow(state.window)
    return true
end

local function app_event(event)
    return gui.gui_process_events(state.ctx, event)
end

local function app_quit()
    if state.texture ~= nil then sdl.SDL_DestroyTexture(state.texture) end
    if state.window ~= nil then sdl.SDL_DestroyWindow(state.window) end
    if state.renderer ~= nil then sdl.SDL_DestroyRenderer(state.renderer) end
    sdl.SDL_Quit()
end

local function app_iterate()
    local value = ffi.new("int[1]", 64)
    local frames = 0

    -- Layout constants mirroring gui_slider geometry
    local SLIDER_X, SLIDER_Y = 70, 50
    local SLIDER_XSIZE, SLIDER_YSIZE, SLIDER_OFFSET = 20, 10, 4
    local SLIDER_WIDTH = 255 + SLIDER_XSIZE + 2 * SLIDER_OFFSET

    return function()
        frames = frames + 1
        gui.gui_begin(state.renderer, state.texture, state.ctx)

        -- Title/instructions
        gui.gui_label(state.ctx, 10, 10, "Interactive slider test")
        gui.gui_label(state.ctx, 10, 28, "Drag the knob with mouse. ESC to quit.")

        -- Slider + live value
        if gui.gui_slider(state.ctx, SLIDER_X, SLIDER_Y, value) then
            -- value changed this frame; render something reactive below
        end
        -- Place both the left label ("Value") and the numeric value label so their vertical centers
        -- align with the slider's vertical centerline, avoiding overlap with the control.
        local slider_center_y = SLIDER_Y + (SLIDER_YSIZE + 2 * SLIDER_OFFSET) / 2
        local function draw_centered_text(x, center_y, text)
            local ext = ffi.new("cairo_text_extents_t")
            cairo.cairo_text_extents(state.ctx.ctx, text, ext)
            -- Position baseline such that the text's vertical center equals center_y
            local baseline_y = center_y - (ext.y_bearing + ext.height / 2)
            cairo.cairo_new_path(state.ctx.ctx)
            cairo.cairo_set_source_rgb(state.ctx.ctx, state.ctx.fg.r, state.ctx.fg.g, state.ctx.fg.b)
            cairo.cairo_move_to(state.ctx.ctx, x, baseline_y)
            cairo.cairo_show_text(state.ctx.ctx, text)
            cairo.cairo_fill(state.ctx.ctx)
        end
        -- Left label
        draw_centered_text(10, slider_center_y, "Value")
        -- Numeric value to the right of the slider
        local value_label_x = SLIDER_X + SLIDER_WIDTH + 8
        draw_centered_text(value_label_x, slider_center_y, tostring(value[0]))

        -- Visual bar reflecting slider value (0-255)
        do
            local bar_x, bar_y, bar_w, bar_h = SLIDER_X, 80, 255, 16
            cairo.cairo_new_path(state.ctx.ctx)
            cairo.cairo_set_source_rgb(state.ctx.ctx, state.ctx.fg.r, state.ctx.fg.g, state.ctx.fg.b)
            cairo.cairo_rectangle(state.ctx.ctx, bar_x, bar_y, bar_w, bar_h)
            cairo.cairo_stroke(state.ctx.ctx)

            local fill_w = math.max(0, math.min(bar_w, value[0]))
            cairo.cairo_new_path(state.ctx.ctx)
            cairo.cairo_set_source_rgb(state.ctx.ctx, state.ctx.acc.r, state.ctx.acc.g, state.ctx.acc.b)
            cairo.cairo_rectangle(state.ctx.ctx, bar_x + 1, bar_y + 1, fill_w - 2, bar_h - 2)
            cairo.cairo_fill(state.ctx.ctx)
        end

        -- Small hint about focus cycling
        gui.gui_label(state.ctx, 10, 110, "Tip: Use TAB to focus, LEFT/RIGHT to adjust.")

        gui.gui_end(state.ctx)

        if RUN_SECONDS and frames >= RUN_SECONDS * TARGET_FPS then
            print(string.format("[auto-exit] Reached %d frames", frames))
            return sdlm.SDL_APP_SUCCESS
        end
        return sdlm.SDL_APP_CONTINUE
    end
end

local function main()
    if RUN_SECONDS then
        print(string.format("[init] Auto-exit after %d seconds @ %d fps", RUN_SECONDS, TARGET_FPS))
        io.stdout:flush()
    end
    local iterate_closure = app_iterate()
    local rc = app_loop.run_loop{
        init = app_init,
        iterate = function() return iterate_closure() end,
        on_event = app_event,
        quit = app_quit,
        options = {
            target_fps = TARGET_FPS,
            run_seconds = RUN_SECONDS,
            set_callback_rate = "10",
            startup_delay_ms = 100,
            startup_drain_cap = 5000,
            per_frame_event_cap = 200,
            yield_on_storm = true,
        }
    }
    return rc
end

local rc = main()
os.exit(rc == sdlm.SDL_APP_SUCCESS and 0 or 1)
