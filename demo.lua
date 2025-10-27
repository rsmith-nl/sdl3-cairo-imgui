#!/usr/bin/env luajit
-- demo.lua
-- Demo application for Cairo ImGui (Lua port)
-- This is free and unencumbered software released into the public domain.
--
-- Original C version by: R.F. Smith <rsmith@xs4all.nl>
-- Lua port: 2025

local ffi = require("ffi")
local sdl_module = require("ffi_sdl3")
local gui = require("cairo_imgui")

local sdl = sdl_module.sdl

-- Frame pacing configuration (can be overridden via IMGUI_FPS)
local TARGET_FPS = tonumber(os.getenv("IMGUI_FPS") or "") or 60
if TARGET_FPS < 1 then TARGET_FPS = 60 end
local FRAME_DELAY_MS = math.floor(1000 / TARGET_FPS)
-- Optional: auto-exit after N seconds and log each frame
local RUN_SECONDS = tonumber(os.getenv("IMGUI_RUN_SECONDS") or "") or nil
local LOG_FRAMES = os.getenv("IMGUI_LOG_FRAMES") == "1"

-- Application state
local state = {
    window = nil,
    renderer = nil,
    texture = nil,
    ctx = nil,
    checked = ffi.new("bool[1]", false),
    running = true
}

-- Initialize SDL and create window
local function app_init()
    -- Create GUI context
    state.ctx = gui.gui_context_new()

    -- Set dark theme
    gui.gui_theme_dark(state.ctx)

    -- Initialize SDL
    if not sdl.SDL_Init(sdl_module.SDL_INIT_VIDEO) then
        print("Couldn't initialize SDL: " .. ffi.string(sdl.SDL_GetError()))
        return false
    end

    -- Set callback rate hint
    sdl.SDL_SetHint(sdl_module.SDL_HINT_MAIN_CALLBACK_RATE, "10")

    -- Create window and renderer
    local window_ptr = ffi.new("SDL_Window*[1]")
    local renderer_ptr = ffi.new("SDL_Renderer*[1]")
    local w, h = 400, 300

    if not sdl.SDL_CreateWindowAndRenderer(
            "Cairo IMGUI Demo (Lua)",
            w, h, 0,
            window_ptr, renderer_ptr
        ) then
        print("Couldn't create window and renderer: " .. ffi.string(sdl.SDL_GetError()))
        return false
    end

    state.window = window_ptr[0]
    state.renderer = renderer_ptr[0]

    io.stderr:write(string.format("[init] Window=%s, Renderer=%s\n",
        tostring(state.window), tostring(state.renderer)))
    io.stderr:flush()

    if state.window == nil or state.renderer == nil then
        io.stderr:write("[init] ERROR: Window or renderer is nil!\n")
        io.stderr:flush()
        return false
    end

    -- Try to ensure the window has focus for keyboard input
    if state.window ~= nil then
        sdl.SDL_RaiseWindow(state.window)
    end

    -- Enable VSync
    sdl.SDL_SetRenderVSync(state.renderer, sdl_module.SDL_RENDERER_VSYNC_ADAPTIVE)

    -- Create texture
    state.texture = sdl.SDL_CreateTexture(
        state.renderer,
        sdl_module.SDL_PIXELFORMAT_ARGB8888,
        sdl_module.SDL_TEXTUREACCESS_STREAMING,
        w, h
    )

    -- Ensure no unexpected alpha blending hides the rendered texture
    sdl.SDL_SetTextureBlendMode(state.texture, sdl_module.SDL_BLENDMODE_NONE)

    return true
end

-- Main application loop iteration
local function app_iterate()
    -- GUI state (static variables in C)
    local count = 0
    local frames = 0
    local bbuf = "Not pressed"
    local slabel = "Not checked"
    local radio = ffi.new("int[1]", 1) -- Start with dark theme
    local red = ffi.new("int[1]", 0)
    local green = ffi.new("int[1]", 0)
    local blue = ffi.new("int[1]", 0)
    local samplecolor = ffi.new("GUI_rgb")
    samplecolor.r, samplecolor.g, samplecolor.b = 0, 0, 0
    local ispinner = ffi.new("int32_t[1]", 17)
    local editstate = gui.gui_editstate_new()

    return function()
        frames = frames + 1
        state.frame_count = frames
        local DEBUG_EVENTS = os.getenv("IMGUI_DEBUG_EVENTS") == "1"
        -- Begin GUI frame
        local ok, err = pcall(function()
            gui.gui_begin(state.renderer, state.texture, state.ctx)
        end)
        if not ok then
            io.stderr:write(string.format("[ERROR] gui_begin failed: %s\n", tostring(err)))
            io.stderr:flush()
            return sdl_module.SDL_APP_FAILURE
        end

        -- Button + label to show counter
        if gui.gui_button(state.ctx, 10, 10, "Test") then
            count = count + 1
            bbuf = string.format("Pressed %d times", count)
        end
        gui.gui_label(state.ctx, 75, 17, bbuf)

        -- (moved) Focus debug overlay is drawn at the end to ensure visibility

        -- Close button
        if gui.gui_button(state.ctx, 10, 260, "Close") then
            return sdl_module.SDL_APP_SUCCESS
        end

        -- Checkbox
        if gui.gui_checkbox(state.ctx, 10, 50, "Checkbox", state.checked) then
            if state.checked[0] then
                slabel = "Checked"
            else
                slabel = "Not checked"
            end
        end
        gui.gui_label(state.ctx, 100, 50, slabel)

        -- Theme radio buttons
        gui.gui_label(state.ctx, 10, 70, "Theme")
        local btns = { "light", "dark" }
        if gui.gui_radiobuttons(state.ctx, 10, 82, btns, radio) then
            if radio[0] == 0 then
                gui.gui_theme_light(state.ctx)
            elseif radio[0] == 1 then
                gui.gui_theme_dark(state.ctx)
            end
        end

        -- Color sliders and sample
        gui.gui_label(state.ctx, 10, 124, "Red")
        gui.gui_label(state.ctx, 10, 154, "Green")
        gui.gui_label(state.ctx, 10, 184, "Blue")

        if gui.gui_slider(state.ctx, 60, 120, red) then
            samplecolor.r = red[0] / 255.0
        end
        if gui.gui_slider(state.ctx, 60, 150, green) then
            samplecolor.g = green[0] / 255.0
        end
        if gui.gui_slider(state.ctx, 60, 180, blue) then
            samplecolor.b = blue[0] / 255.0
        end

        gui.gui_label(state.ctx, 355, 124, tostring(red[0]))
        gui.gui_label(state.ctx, 355, 154, tostring(green[0]))
        gui.gui_label(state.ctx, 355, 184, tostring(blue[0]))
        gui.gui_colorsample(state.ctx, 250.0, 10.0, 100.0, 100.0, samplecolor)

        -- Integer spinner
        gui.gui_ispinner(state.ctx, 65.0, 210.0, 0, 255, ispinner)

        -- Edit box
        gui.gui_editbox(state.ctx, 150.0, 210.0, 100.0, editstate)

        -- Show cursor position
        local buf = string.format("x = %d, y = %d", state.ctx.mouse_x, state.ctx.mouse_y)
        gui.gui_label(state.ctx, 100, 270, buf)
        -- Debug overlay: frame counter to detect stuck frames
        gui.gui_label(state.ctx, 300, 270, "frame: " .. tostring(frames))

        -- Small animated indicator to visibly confirm frame updates
        do
            local rw = ffi.new("int[1]")
            local rh = ffi.new("int[1]")
            sdl.SDL_GetCurrentRenderOutputSize(state.renderer, rw, rh)
            if rw[0] <= 0 then rw[0] = 400 end
            -- Move a tiny rectangle horizontally across the top
            local x = 10 + ((frames * 3) % math.max(10, (rw[0] - 40)))
            local y = 8
            -- Use Cairo directly through the context
            local cairo = require("ffi_cairo").cairo
            cairo.cairo_new_path(state.ctx.ctx)
            cairo.cairo_set_source_rgb(state.ctx.ctx, state.ctx.acc.r, state.ctx.acc.g, state.ctx.acc.b)
            cairo.cairo_rectangle(state.ctx.ctx, x, y, 6.0, 6.0)
            cairo.cairo_fill(state.ctx.ctx)

            -- Focus debug overlay (top-right) drawn last for visibility
            do
                local label = string.format("focus: %d/%d", tonumber(state.ctx.id or 0), tonumber(state.ctx.maxid or 0))
                local ext = ffi.new("cairo_text_extents_t")
                -- Measure text width/height
                cairo.cairo_text_extents(state.ctx.ctx, label, ext)
                local pad = 6.0
                local box_w = ext.width + 2 * pad
                local box_h = ext.height + 2 * pad
                local bx = math.max(0, rw[0] - box_w - 10)
                local by = 6.0
                -- Background with slight transparency for contrast
                cairo.cairo_new_path(state.ctx.ctx)
                cairo.cairo_set_source_rgba(state.ctx.ctx, 0, 0, 0, 0.35)
                cairo.cairo_rectangle(state.ctx.ctx, bx, by, box_w, box_h)
                cairo.cairo_fill(state.ctx.ctx)
                -- Text on top
                cairo.cairo_new_path(state.ctx.ctx)
                cairo.cairo_set_source_rgb(state.ctx.ctx, state.ctx.fg.r, state.ctx.fg.g, state.ctx.fg.b)
                cairo.cairo_move_to(state.ctx.ctx, bx + pad, by + pad + ext.height)
                cairo.cairo_show_text(state.ctx.ctx, label)
                cairo.cairo_fill(state.ctx.ctx)
            end
        end

        -- End GUI frame
        gui.gui_end(state.ctx)

        if LOG_FRAMES then
            print(string.format("[frame] %d", frames))
            io.stdout:flush()
        end

        return sdl_module.SDL_APP_CONTINUE
    end
end

-- Process SDL events
local function app_event(event)
    return gui.gui_process_events(state.ctx, event)
end

-- Cleanup
local function app_quit()
    if state.texture ~= nil then
        sdl.SDL_DestroyTexture(state.texture)
    end
    if state.window ~= nil then
        sdl.SDL_DestroyWindow(state.window)
    end
    if state.renderer ~= nil then
        sdl.SDL_DestroyRenderer(state.renderer)
    end
    sdl.SDL_Quit()
end

-- Main entry point
local function main()
    if RUN_SECONDS then
        print(string.format("[init] Auto-exit enabled: %d seconds @ %d fps = %d frames",
            RUN_SECONDS, TARGET_FPS, RUN_SECONDS * TARGET_FPS))
        io.stdout:flush()
    end

    if not app_init() then
        return sdl_module.SDL_APP_FAILURE
    end

    -- Create iteration closure
    local iterate = app_iterate()

    -- Small delay to let window manager settle (prevents spurious early QUIT/events floods)
    sdl.SDL_Delay(100)

    -- Drain any initialization events (with cap to avoid starvation on event storms)
    local event_init = ffi.new("SDL_Event")
    do
        local drained = 0
        while sdl.SDL_PollEvent(event_init) do
            drained = drained + 1
            if drained >= 5000 then break end
        end
        if os.getenv("IMGUI_DEBUG_EVENTS") == "1" then
            io.stderr:write(string.format("[init] Drained %d startup events\n", drained))
            io.stderr:flush()
        end
    end

    -- Main event/render loop (pacing by TARGET_FPS)
    local event = ffi.new("SDL_Event")
    local target_frames = nil
    if RUN_SECONDS and RUN_SECONDS > 0 then
        target_frames = RUN_SECONDS * TARGET_FPS
    end

    io.stderr:write(string.format("[main] Starting event loop, target_frames=%s\n", tostring(target_frames)))
    io.stderr:flush()

    while state.running do
        -- Process pending events with a per-frame cap to avoid starvation during event floods
        do
            local processed = 0
            while sdl.SDL_PollEvent(event) do
                local result = app_event(event)
                if result == sdl_module.SDL_APP_SUCCESS or result == sdl_module.SDL_APP_FAILURE then
                    state.running = false
                    break
                end
                processed = processed + 1
                if processed >= 200 then
                    break
                end
            end
            if processed >= 200 then
                -- Give the renderer a chance if there's an event storm
                sdl.SDL_Delay(1)
            end
        end

        if not state.running then break end

        -- Render a frame
        local result = iterate()
        if result == sdl_module.SDL_APP_SUCCESS or result == sdl_module.SDL_APP_FAILURE then
            state.running = false
            break
        end

        -- Check auto-exit after rendering frame (only if configured)
        if target_frames and (state.frame_count or 0) >= target_frames then
            print(string.format("[auto-exit] Reached %d frames", state.frame_count))
            io.stdout:flush()
            state.running = false
            break
        end

        -- Frame pacing
        if FRAME_DELAY_MS > 0 then
            sdl.SDL_Delay(FRAME_DELAY_MS)
        end
    end

    app_quit()
    print(string.format("[exit] Completed with %d frames rendered", state.frame_count or 0))
    io.stdout:flush()
    return sdl_module.SDL_APP_SUCCESS
end

-- Run the application
local result = main()
if result == sdl_module.SDL_APP_FAILURE then
    os.exit(1)
else
    os.exit(0)
end
