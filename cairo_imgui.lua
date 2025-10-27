-- cairo_imgui.lua
-- Simple immediate mode GUI for SDL3 and Cairo (Lua port)
-- This is free and unencumbered software released into the public domain.
--
-- Original C version by: R.F. Smith <rsmith@xs4all.nl>
-- Lua port: 2025

local ffi = require("ffi")
local bit = require("bit")
local sdl_module = require("ffi_sdl3")
local cairo_module = require("ffi_cairo")

local sdl = sdl_module.sdl
local cairo = cairo_module.cairo

-- Define GUI structures
ffi.cdef [[
typedef struct {
    double r;
    double g;
    double b;
} GUI_rgb;

typedef struct {
    void *renderer;      // SDL_Renderer*
    void *texture;       // SDL_Texture*
    void *surface;       // cairo_surface_t*
    void *ctx;           // cairo_t*
    int32_t mouse_x, mouse_y;
    int32_t id;
    int32_t keycode;
    int32_t counter;
    int32_t maxid;
    int16_t mod;
    bool button_pressed;
    bool button_released;
    GUI_rgb fg;
    GUI_rgb bg;
    GUI_rgb acc;
} GUI_context;

typedef struct {
    char data[256];
    ptrdiff_t used;
    ptrdiff_t cursorpos;
    ptrdiff_t displaypos;
} GUI_editstate;
]]

-- Module-level variables
local m_width, m_height = 0, 0
-- Track active dragging for sliders (by widget id) so grabbing the handle works reliably
local active_drag_id = 0
-- Drag tracking for sliders to prevent value jumps on drag start
local drag_start_mouse_x = 0
local drag_start_value = 0

-- Create GUI context
local function gui_context_new()
    local ctx = ffi.new("GUI_context")
    ctx.id = 1
    ctx.counter = 1
    ctx.maxid = 0
    ctx.mouse_x = 0
    ctx.mouse_y = 0
    ctx.keycode = 0
    ctx.mod = 0
    ctx.button_pressed = false
    ctx.button_released = false
    return ctx
end

-- Create edit state
local function gui_editstate_new()
    local state = ffi.new("GUI_editstate")
    state.used = 0
    state.cursorpos = 0
    state.displaypos = 0
    return state
end

-- Begin GUI frame
local function gui_begin(renderer, texture, ctx)
    assert(renderer ~= nil, "renderer is nil")
    assert(texture ~= nil, "texture is nil")
    assert(ctx ~= nil, "ctx is nil")

    local pixels = ffi.new("void*[1]")
    local pitch = ffi.new("int[1]")
    local w = ffi.new("int[1]")
    local h = ffi.new("int[1]")

    ctx.renderer = renderer
    ctx.texture = texture

    sdl.SDL_GetCurrentRenderOutputSize(renderer, w, h)

    -- Lock texture and create Cairo surface
    sdl.SDL_LockTexture(texture, nil, pixels, pitch)

    ctx.surface = cairo.cairo_image_surface_create_for_data(
        ffi.cast("unsigned char*", pixels[0]),
        cairo_module.CAIRO_FORMAT_ARGB32,
        w[0], h[0], pitch[0]
    )

    -- Create Cairo context
    ctx.ctx = cairo.cairo_create(ctx.surface)

    -- Set background color and fill
    cairo.cairo_set_source_rgb(ctx.ctx, ctx.bg.r, ctx.bg.g, ctx.bg.b)
    cairo.cairo_paint(ctx.ctx)

    -- Set font size
    cairo.cairo_set_font_size(ctx.ctx, 14.0)

    -- Determine the size of a capital M
    local ext = ffi.new("cairo_text_extents_t")
    cairo.cairo_text_extents(ctx.ctx, "M", ext)
    m_width = ext.width
    m_height = ext.height

    ctx.counter = 1
end

-- End GUI frame
local function gui_end(ctx)
    assert(ctx ~= nil)

    ctx.button_released = false
    ctx.keycode = 0
    ctx.mod = 0

    -- Clean up Cairo
    -- Ensure all drawing is flushed to the surface memory before destroy/unlock
    cairo.cairo_surface_flush(ctx.surface)
    cairo.cairo_destroy(ctx.ctx)
    cairo.cairo_surface_destroy(ctx.surface)
    ctx.surface = nil

    -- Unlock texture and present
    sdl.SDL_UnlockTexture(ctx.texture)
    local ok = sdl.SDL_RenderTexture(ctx.renderer, ctx.texture, nil, nil)
    if ok == 0 then
        local err = sdl.SDL_GetError()
        if err ~= nil then
            print("[render] SDL_RenderTexture failed: " .. ffi.string(err))
        else
            print("[render] SDL_RenderTexture failed")
        end
    end
    ok = sdl.SDL_RenderPresent(ctx.renderer)
    if ok == 0 then
        local err = sdl.SDL_GetError()
        if err ~= nil then
            print("[render] SDL_RenderPresent failed: " .. ffi.string(err))
        else
            print("[render] SDL_RenderPresent failed")
        end
    end

    -- maxid equals the last assigned widget id this frame (counter starts at 1 and increments after each widget)
    ctx.maxid = ctx.counter - 1
end

-- Theme functions
local function gui_theme_light(ctx)
    ctx.bg.r, ctx.bg.g, ctx.bg.b = 0.992157, 0.964706, 0.890196   -- Base3 #fdf6e3
    ctx.fg.r, ctx.fg.g, ctx.fg.b = 0.345098, 0.431373, 0.458824   -- Base01 #586e75
    ctx.acc.r, ctx.acc.g, ctx.acc.b = 0.14902, 0.545098, 0.823529 -- Blue #268bd2
end

local function gui_theme_dark(ctx)
    ctx.bg.r, ctx.bg.g, ctx.bg.b = 0.027451, 0.211765, 0.258824   -- Base02 #073642
    ctx.fg.r, ctx.fg.g, ctx.fg.b = 0.576471, 0.631373, 0.631373   -- Base1 #93a1a1
    ctx.acc.r, ctx.acc.g, ctx.acc.b = 0.14902, 0.545098, 0.823529 -- Blue #268bd2
end

-- Process SDL events
local function gui_process_events(ctx, event)
    local w = ffi.new("int[1]")
    local h = ffi.new("int[1]")
    local DEBUG_EVENTS = os.getenv("IMGUI_DEBUG_EVENTS") == "1"

    if event.type == sdl_module.SDL_EVENT_WINDOW_RESIZED then
        if DEBUG_EVENTS then print("[evt] WINDOW_RESIZED") end
        -- Resize texture if window size changes
        sdl.SDL_DestroyTexture(ctx.texture)
        sdl.SDL_GetWindowSize(sdl.SDL_GetRenderWindow(ctx.renderer), w, h)
        ctx.texture = sdl.SDL_CreateTexture(
            ctx.renderer,
            sdl_module.SDL_PIXELFORMAT_ARGB8888,
            sdl_module.SDL_TEXTUREACCESS_STREAMING,
            w[0], h[0]
        )
        -- Ensure texture isn't blended away
        sdl.SDL_SetTextureBlendMode(ctx.texture, sdl_module.SDL_BLENDMODE_NONE)
    elseif event.type == sdl_module.SDL_EVENT_QUIT then
        if DEBUG_EVENTS then print("[evt] QUIT") end
        return sdl_module.SDL_APP_SUCCESS
    elseif event.type == sdl_module.SDL_EVENT_KEY_UP then
        if DEBUG_EVENTS then print(string.format("[evt] KEY_UP key=%d mod=%d", event.key.key, event.key.mod)) end
        -- Only quit on ESC (not 'q' to allow typing it in editbox)
        if event.key.key == sdl_module.SDLK_ESCAPE then
            return sdl_module.SDL_APP_SUCCESS
        end
    elseif event.type == sdl_module.SDL_EVENT_KEY_DOWN then
        if DEBUG_EVENTS then
            print(string.format("[evt] KEY_DOWN key=%d mod=%d repeat=%d", event.key.key, event.key.mod,
                event.key['repeat']))
        end
        -- Only quit on ESC (not 'q' to allow typing it in editbox)
        if event.key.key == sdl_module.SDLK_ESCAPE then
            return sdl_module.SDL_APP_SUCCESS
        end
        -- Handle TAB focus cycling on key down to support key repeat
        if event.key.key == sdl_module.SDLK_TAB then
            if bit.band(event.key.mod, bit.bor(sdl_module.SDL_KMOD_LSHIFT, sdl_module.SDL_KMOD_RSHIFT)) ~= 0 then
                ctx.id = ctx.id - 1
                if ctx.id < 1 then
                    ctx.id = ctx.maxid
                end
            else
                ctx.id = ctx.id + 1
                if ctx.id > ctx.maxid then
                    ctx.id = 1
                end
            end
            return sdl_module.SDL_APP_CONTINUE
        end
        -- Handle navigation/editing keys on key down to support key repeat
        -- (when holding down arrow keys, HOME, END, DELETE, BACKSPACE)
        local nav_keys = {
            [sdl_module.SDLK_LEFT] = true,
            [sdl_module.SDLK_RIGHT] = true,
            [sdl_module.SDLK_HOME] = true,
            [sdl_module.SDLK_END] = true,
            [sdl_module.SDLK_DELETE] = true,
            [sdl_module.SDLK_BACKSPACE] = true,
        }
        if nav_keys[event.key.key] then
            ctx.keycode = event.key.key
            ctx.mod = event.key.mod
        else
            -- For regular typing, use KEY_DOWN so OS key repeat generates repeated characters
            ctx.keycode = event.key.key
            ctx.mod = event.key.mod
        end
    elseif event.type == sdl_module.SDL_EVENT_MOUSE_MOTION then
        if DEBUG_EVENTS then -- don't spam too much, sample only occasionally
            if (ctx.counter % 50) == 0 then
                print(string.format("[evt] MOUSE_MOTION x=%.1f y=%.1f", event.motion.x, event.motion.y))
            end
        end
        ctx.mouse_x = math.floor(event.motion.x)
        ctx.mouse_y = math.floor(event.motion.y)
    elseif event.type == sdl_module.SDL_EVENT_MOUSE_BUTTON_DOWN then
        if DEBUG_EVENTS then print(string.format("[evt] MOUSE_DOWN x=%.1f y=%.1f", event.button.x, event.button.y)) end
        -- Update mouse position from button event (motion events may not fire if mouse is still)
        ctx.mouse_x = math.floor(event.button.x)
        ctx.mouse_y = math.floor(event.button.y)
        ctx.button_pressed = true
        ctx.button_released = false
    elseif event.type == sdl_module.SDL_EVENT_MOUSE_BUTTON_UP then
        if DEBUG_EVENTS then print(string.format("[evt] MOUSE_UP x=%.1f y=%.1f", event.button.x, event.button.y)) end
        -- Update mouse position from button event
        ctx.mouse_x = math.floor(event.button.x)
        ctx.mouse_y = math.floor(event.button.y)
        ctx.button_pressed = false
        ctx.button_released = true
        -- Stop any active slider drag on mouse release
        active_drag_id = 0
    else
        -- Do not clear button_released here to avoid losing clicks when
        -- unrelated events arrive after MOUSE_BUTTON_UP within the same frame.
    end

    return sdl_module.SDL_APP_CONTINUE
end

-- Widget: Label
local function gui_label(ctx, x, y, label)
    assert(ctx ~= nil)
    local ext = ffi.new("cairo_text_extents_t")
    cairo.cairo_text_extents(ctx.ctx, label, ext)

    cairo.cairo_new_path(ctx.ctx)
    cairo.cairo_set_source_rgb(ctx.ctx, ctx.fg.r, ctx.fg.g, ctx.fg.b)
    cairo.cairo_move_to(ctx.ctx, x, y + ext.height)
    cairo.cairo_show_text(ctx.ctx, label)
    cairo.cairo_fill(ctx.ctx)
end

-- Widget: Button
local function gui_button(ctx, x, y, label)
    assert(ctx ~= nil)
    local id = ctx.counter
    ctx.counter = ctx.counter + 1
    local rv = false
    local offset = 10.0
    local DEBUG_BUTTONS = os.getenv("IMGUI_DEBUG_BUTTONS") == "1"

    local ext = ffi.new("cairo_text_extents_t")
    cairo.cairo_text_extents(ctx.ctx, label, ext)
    local width = 2 * offset + ext.width
    local height = 2 * offset + ext.height

    -- Draw button outline
    cairo.cairo_new_path(ctx.ctx)
    cairo.cairo_set_source_rgb(ctx.ctx, ctx.fg.r, ctx.fg.g, ctx.fg.b)
    cairo.cairo_rectangle(ctx.ctx, x, y, width, height)
    cairo.cairo_stroke(ctx.ctx)

    -- Check if mouse is inside or we have focus
    local mouse_in = (ctx.mouse_x >= x and (ctx.mouse_x - x) <= width and
        ctx.mouse_y >= y and (ctx.mouse_y - y) <= height)
    if mouse_in or ctx.id == id then
        ctx.id = id
        cairo.cairo_new_path(ctx.ctx)
        cairo.cairo_set_source_rgb(ctx.ctx, ctx.acc.r, ctx.acc.g, ctx.acc.b)
        cairo.cairo_rectangle(ctx.ctx, x + 1, y + 1, width - 2, height - 2)
        if ctx.button_pressed then
            cairo.cairo_fill(ctx.ctx)
            if DEBUG_BUTTONS and mouse_in then
                io.stderr:write(string.format("[btn] down id=%d label='%s' mx=%d my=%d rect={%.1f,%.1f,%.1f,%.1f}\n",
                    id, label, ctx.mouse_x, ctx.mouse_y, x, y, width, height))
                io.stderr:flush()
            end
        else
            cairo.cairo_stroke(ctx.ctx)
        end
        -- Activation logic:
        -- - Mouse: require release while mouse is inside the button rect
        -- - Keyboard: allow Enter/Space when the button has focus
        if ((mouse_in and ctx.button_released)
                or ctx.keycode == sdl_module.SDLK_RETURN
                or ctx.keycode == sdl_module.SDLK_SPACE) then
            rv = true
            if DEBUG_BUTTONS then
                local where = mouse_in and "inside" or (ctx.id == id and "focused") or "outside"
                io.stderr:write(string.format("[btn] click id=%d label='%s' %s mx=%d my=%d rect={%.1f,%.1f,%.1f,%.1f}\n",
                    id, label, where, ctx.mouse_x, ctx.mouse_y, x, y, width, height))
                io.stderr:flush()
            end
        end
    end

    -- Draw the label
    cairo.cairo_new_path(ctx.ctx)
    cairo.cairo_set_source_rgb(ctx.ctx, ctx.fg.r, ctx.fg.g, ctx.fg.b)
    cairo.cairo_move_to(ctx.ctx, x + offset, y + offset + ext.height)
    cairo.cairo_show_text(ctx.ctx, label)
    cairo.cairo_fill(ctx.ctx)

    return rv
end

-- Widget: Checkbox
local function gui_checkbox(ctx, x, y, label, state)
    assert(ctx ~= nil)
    local id = ctx.counter
    ctx.counter = ctx.counter + 1
    local rv = false
    local offset = 5.0
    local boxsize = math.max(m_width, m_height)

    local ext = ffi.new("cairo_text_extents_t")
    cairo.cairo_text_extents(ctx.ctx, label, ext)
    local width = 2 * offset + ext.width + boxsize
    local height = 2 * offset + math.max(ext.height, boxsize)

    -- Draw checkbox outline
    cairo.cairo_new_path(ctx.ctx)
    cairo.cairo_set_source_rgb(ctx.ctx, ctx.fg.r, ctx.fg.g, ctx.fg.b)
    cairo.cairo_rectangle(ctx.ctx, x, y, boxsize, boxsize)
    cairo.cairo_stroke(ctx.ctx)

    -- Check if mouse is inside or we have focus
    if (ctx.mouse_x >= x and (ctx.mouse_x - x) <= width and
            ctx.mouse_y >= y and (ctx.mouse_y - y) <= height) or ctx.id == id then
        ctx.id = id
        cairo.cairo_new_path(ctx.ctx)
        cairo.cairo_set_source_rgb(ctx.ctx, ctx.acc.r, ctx.acc.g, ctx.acc.b)
        cairo.cairo_rectangle(ctx.ctx, x + 1, y + 1, boxsize - 2, boxsize - 2)
        if ctx.button_pressed then
            cairo.cairo_fill(ctx.ctx)
        else
            cairo.cairo_stroke(ctx.ctx)
        end
        if ctx.button_released or ctx.keycode == sdl_module.SDLK_RETURN or ctx.keycode == sdl_module.SDLK_SPACE then
            rv = true
            state[0] = not state[0]
        end
    end

    -- Draw selected mark if needed
    if state[0] then
        cairo.cairo_new_path(ctx.ctx)
        cairo.cairo_set_source_rgb(ctx.ctx, ctx.fg.r, ctx.fg.g, ctx.fg.b)
        cairo.cairo_move_to(ctx.ctx, x, y)
        cairo.cairo_rel_line_to(ctx.ctx, boxsize, boxsize)
        cairo.cairo_rel_move_to(ctx.ctx, 0, -boxsize)
        cairo.cairo_rel_line_to(ctx.ctx, -boxsize, boxsize)
        cairo.cairo_stroke(ctx.ctx)
    end

    -- Draw the label
    cairo.cairo_new_path(ctx.ctx)
    cairo.cairo_set_source_rgb(ctx.ctx, ctx.fg.r, ctx.fg.g, ctx.fg.b)
    cairo.cairo_move_to(ctx.ctx, x + boxsize + offset, y + boxsize / 2 + ext.height / 2)
    cairo.cairo_show_text(ctx.ctx, label)
    cairo.cairo_fill(ctx.ctx)

    return rv
end

-- Widget: Radio buttons
local function gui_radiobuttons(ctx, x, y, labels, state)
    assert(ctx ~= nil)
    assert(labels ~= nil)
    local nlabels = #labels
    assert(nlabels > 0)

    local id = ctx.counter
    ctx.counter = ctx.counter + 1
    local rv = false
    local offset = 5.0
    local boxsize = math.max(m_width, m_height) * 1.5

    -- Calculate dimensions
    local heights = {}
    local exty = {}
    local width = 0
    local height = 0
    local ext = ffi.new("cairo_text_extents_t")

    for k = 1, nlabels do
        cairo.cairo_text_extents(ctx.ctx, labels[k], ext)
        heights[k] = math.max(ext.height, boxsize)
        exty[k] = ext.height
        if width < ext.width then
            width = ext.width
        end
        height = height + heights[k]
    end
    width = width + 2 * offset + boxsize
    height = height + 2 * offset

    -- Draw the buttons and the selected one
    cairo.cairo_set_source_rgb(ctx.ctx, ctx.fg.r, ctx.fg.g, ctx.fg.b)
    local cury = y + boxsize / 2
    local curx = x + boxsize / 2

    for k = 1, nlabels do
        cairo.cairo_new_path(ctx.ctx)
        cairo.cairo_arc(ctx.ctx, curx, cury, boxsize / 2 - 2, 0.0, 2 * math.pi)
        cairo.cairo_stroke(ctx.ctx)
        if state[0] == (k - 1) then -- Lua is 1-indexed, state is 0-indexed
            cairo.cairo_new_path(ctx.ctx)
            cairo.cairo_arc(ctx.ctx, curx, cury, boxsize / 2 - 4, 0.0, 2 * math.pi)
            cairo.cairo_fill(ctx.ctx)
        end
        cury = cury + heights[k]
    end

    -- Draw the labels
    cury = y + offset
    curx = x + boxsize + offset
    cairo.cairo_new_path(ctx.ctx)
    cairo.cairo_set_source_rgb(ctx.ctx, ctx.fg.r, ctx.fg.g, ctx.fg.b)
    for k = 1, nlabels do
        cairo.cairo_move_to(ctx.ctx, curx, cury + exty[k] / 2)
        cairo.cairo_show_text(ctx.ctx, labels[k])
        cury = cury + heights[k]
    end
    cairo.cairo_fill(ctx.ctx)

    -- Check for interaction
    local mouse_in_box = (ctx.mouse_x >= x and (ctx.mouse_x - x) <= width and
        ctx.mouse_y >= y and (ctx.mouse_y - y) <= height)
    if mouse_in_box or ctx.id == id then
        ctx.id = id
        cairo.cairo_new_path(ctx.ctx)
        cairo.cairo_set_source_rgb(ctx.ctx, ctx.acc.r, ctx.acc.g, ctx.acc.b)
        cury = y + boxsize / 2
        curx = x + boxsize / 2

        for k = 1, nlabels do
            local item_hit = math.abs(ctx.mouse_y - cury) < exty[k] / 2
            if item_hit or (not mouse_in_box and state[0] == (k - 1)) then
                cairo.cairo_new_path(ctx.ctx)
                cairo.cairo_arc(ctx.ctx, curx, cury, boxsize / 2 - 3, 0.0, 2 * math.pi)
                if ctx.button_pressed then
                    cairo.cairo_fill(ctx.ctx)
                else
                    cairo.cairo_stroke(ctx.ctx)
                end
                if ctx.button_released or ctx.keycode == sdl_module.SDLK_RETURN or ctx.keycode == sdl_module.SDLK_SPACE then
                    rv = true
                    state[0] = k - 1
                elseif ctx.keycode == sdl_module.SDLK_UP or ctx.keycode == sdl_module.SDLK_LEFT then
                    state[0] = state[0] - 1
                    if state[0] < 0 then
                        state[0] = nlabels - 1
                    end
                    rv = true
                elseif ctx.keycode == sdl_module.SDLK_DOWN or ctx.keycode == sdl_module.SDLK_RIGHT then
                    state[0] = state[0] + 1
                    if state[0] == nlabels then
                        state[0] = 0
                    end
                    rv = true
                end
                break
            end
            cury = cury + heights[k]
        end
    end

    return rv
end

-- Widget: Color sample
local function gui_colorsample(ctx, x, y, w, h, rgb)
    assert(ctx ~= nil)
    assert(rgb ~= nil)
    cairo.cairo_new_path(ctx.ctx)
    cairo.cairo_set_source_rgb(ctx.ctx, rgb.r, rgb.g, rgb.b)
    cairo.cairo_rectangle(ctx.ctx, x, y, w, h)
    cairo.cairo_fill(ctx.ctx)
end

-- Widget: Slider
local function gui_slider(ctx, x, y, state)
    assert(ctx ~= nil)
    assert(state ~= nil)
    local id = ctx.counter
    ctx.counter = ctx.counter + 1
    local changed = false
    local xsize = 20.0
    local ysize = 10.0
    local offset = 4.0
    local width = 255.0 + xsize + 2 * offset
    local height = ysize + 2 * offset

    -- Draw outside rectangle
    cairo.cairo_new_path(ctx.ctx)
    cairo.cairo_set_source_rgb(ctx.ctx, ctx.fg.r, ctx.fg.g, ctx.fg.b)
    cairo.cairo_rectangle(ctx.ctx, x, y, width, height)
    cairo.cairo_stroke(ctx.ctx)

    -- Precompute hover
    local mouse_in = (ctx.mouse_x >= x and (ctx.mouse_x - x) <= width and
        ctx.mouse_y >= y and (ctx.mouse_y - y) <= height)

    -- If we are currently dragging THIS slider, keep updating regardless of hover/focus,
    -- using the delta from the drag start to avoid initial jumps.
    if active_drag_id == id and ctx.button_pressed then
        ctx.id = id -- lock focus during drag
        local dx = math.floor((ctx.mouse_x - drag_start_mouse_x) + 0.5)
        local newstate = drag_start_value + dx
        if newstate ~= state[0] then
            state[0] = newstate
            changed = true
        end
    end

    -- Check for interaction when hovered or focused
    if mouse_in or ctx.id == id then
        ctx.id = id
        cairo.cairo_new_path(ctx.ctx)
        cairo.cairo_set_source_rgb(ctx.ctx, ctx.acc.r, ctx.acc.g, ctx.acc.b)
        cairo.cairo_rectangle(ctx.ctx, x + 2, y + 2, width - 4, height - 4)
        cairo.cairo_stroke(ctx.ctx)

        -- Determine current knob rectangle for precise hit-testing
        local cur = state[0]
        if cur < 0 then cur = 0 elseif cur > 255 then cur = 255 end
        local knob_x0 = x + cur + offset
        local knob_y0 = y + offset
        local knob_x1 = knob_x0 + xsize
        local knob_y1 = knob_y0 + ysize

        local mouse_in_knob = (ctx.mouse_x >= knob_x0 and ctx.mouse_x <= knob_x1 and
            ctx.mouse_y >= knob_y0 and ctx.mouse_y <= knob_y1)

        -- Begin dragging when mouse is pressed anywhere on the slider track.
        -- We avoid initial jumps by tracking delta from the press position.
        if ctx.button_pressed and mouse_in and active_drag_id == 0 then
            active_drag_id = id
            if mouse_in_knob then
                -- Start drag from the current value without changing it, so no jump
                drag_start_mouse_x = ctx.mouse_x
                drag_start_value = state[0]
            else
                -- Clicked on the track: move value to click position immediately, then drag
                local click_val = math.floor(ctx.mouse_x - x - offset - xsize / 2.0 + 0.5)
                if click_val ~= state[0] then
                    state[0] = click_val
                    changed = true
                end
                drag_start_mouse_x = ctx.mouse_x
                drag_start_value = state[0]
            end
        end

        if ctx.keycode == sdl_module.SDLK_LEFT then
            state[0] = state[0] - 1
            changed = true
        elseif ctx.keycode == sdl_module.SDLK_RIGHT then
            state[0] = state[0] + 1
            changed = true
        end
    end

    -- Clamp state
    if state[0] < 0 then
        state[0] = 0
    elseif state[0] > 255 then
        state[0] = 255
    end

    -- Draw slider
    local sliderpos = x + state[0] + offset
    cairo.cairo_new_path(ctx.ctx)
    cairo.cairo_set_source_rgb(ctx.ctx, ctx.fg.r, ctx.fg.g, ctx.fg.b)
    cairo.cairo_rectangle(ctx.ctx, sliderpos, y + offset, xsize, ysize)
    cairo.cairo_fill(ctx.ctx)

    return changed
end

-- Widget: Integer spinner
local function gui_ispinner(ctx, x, y, min, max, state)
    assert(ctx ~= nil)
    assert(state ~= nil)
    assert(max > min)
    local id = ctx.counter
    ctx.counter = ctx.counter + 1
    local rv = false

    -- Estimate width needed to render the extremal value; avoid math.log10 for broader Lua compatibility
    local max_abs = math.max(math.abs(min), math.abs(max))
    local digits = #tostring(max_abs)
    if min < 0 then
        -- Reserve space for minus sign when negatives are possible
        digits = digits + 1
    end
    local maxw = digits * m_width
    local offset = 6.0
    local boxsize = 12.0
    local width = maxw + 2 * offset + 2 * boxsize
    local height = m_height + 2 * offset

    -- Draw outline
    cairo.cairo_new_path(ctx.ctx)
    cairo.cairo_set_source_rgb(ctx.ctx, ctx.fg.r, ctx.fg.g, ctx.fg.b)
    cairo.cairo_rectangle(ctx.ctx, x, y, width, height)
    cairo.cairo_stroke(ctx.ctx)

    -- Draw spinner buttons (up/down triangles)
    cairo.cairo_new_path(ctx.ctx)
    cairo.cairo_set_source_rgb(ctx.ctx, ctx.fg.r, ctx.fg.g, ctx.fg.b)
    cairo.cairo_move_to(ctx.ctx, x + offset + maxw, y + offset + m_height)
    cairo.cairo_rel_line_to(ctx.ctx, boxsize, 0)
    cairo.cairo_rel_line_to(ctx.ctx, -boxsize / 2, -boxsize)
    cairo.cairo_rel_line_to(ctx.ctx, -boxsize / 2, boxsize)
    cairo.cairo_close_path(ctx.ctx)
    cairo.cairo_fill(ctx.ctx)

    cairo.cairo_new_path(ctx.ctx)
    cairo.cairo_set_source_rgb(ctx.ctx, ctx.fg.r, ctx.fg.g, ctx.fg.b)
    cairo.cairo_move_to(ctx.ctx, x + offset + maxw + boxsize, y + offset)
    cairo.cairo_rel_line_to(ctx.ctx, boxsize, 0)
    cairo.cairo_rel_line_to(ctx.ctx, -boxsize / 2, boxsize)
    cairo.cairo_rel_line_to(ctx.ctx, -boxsize / 2, -boxsize)
    cairo.cairo_close_path(ctx.ctx)
    cairo.cairo_fill(ctx.ctx)

    -- Check for interaction
    if (ctx.mouse_x >= x and (ctx.mouse_x - x) <= width and
            ctx.mouse_y >= y and (ctx.mouse_y - y) <= height) or ctx.id == id then
        ctx.id = id
        cairo.cairo_new_path(ctx.ctx)
        cairo.cairo_set_source_rgb(ctx.ctx, ctx.acc.r, ctx.acc.g, ctx.acc.b)
        cairo.cairo_rectangle(ctx.ctx, x + 2, y + 2, width - 4, height - 4)
        cairo.cairo_stroke(ctx.ctx)

        if ctx.button_pressed then
            local xdist = ctx.mouse_x - x - offset - maxw
            if xdist < boxsize then
                state[0] = state[0] + 1
                rv = true
            elseif xdist > boxsize then
                state[0] = state[0] - 1
                rv = true
            end
        end

        if ctx.keycode == sdl_module.SDLK_UP then
            state[0] = state[0] + 1
            rv = true
        elseif ctx.keycode == sdl_module.SDLK_DOWN then
            state[0] = state[0] - 1
            rv = true
        end
    end

    -- Clamp state
    if state[0] > max then
        state[0] = max
    elseif state[0] < min then
        state[0] = min
    end

    -- Draw the number
    local buf = tostring(state[0])
    local ext = ffi.new("cairo_text_extents_t")
    cairo.cairo_text_extents(ctx.ctx, buf, ext)
    cairo.cairo_new_path(ctx.ctx)
    cairo.cairo_set_source_rgb(ctx.ctx, ctx.fg.r, ctx.fg.g, ctx.fg.b)
    cairo.cairo_move_to(ctx.ctx, x + offset, y + offset + ext.height)
    cairo.cairo_show_text(ctx.ctx, buf)

    return rv
end

-- Widget: Edit box
local function gui_editbox(ctx, x, y, w, state)
    assert(ctx ~= nil)
    assert(state ~= nil)
    local id = ctx.counter
    ctx.counter = ctx.counter + 1
    local rv = false
    local offset = 6.0
    local height = m_height + 2 * offset

    -- Draw outline
    cairo.cairo_new_path(ctx.ctx)
    cairo.cairo_set_source_rgb(ctx.ctx, ctx.fg.r, ctx.fg.g, ctx.fg.b)
    cairo.cairo_rectangle(ctx.ctx, x, y, w, height)
    cairo.cairo_stroke(ctx.ctx)

    -- Check for interaction
    if (ctx.mouse_x >= x and (ctx.mouse_x - x) <= w and
            ctx.mouse_y >= y and (ctx.mouse_y - y) <= height) or ctx.id == id then
        ctx.id = id
        cairo.cairo_new_path(ctx.ctx)
        cairo.cairo_set_source_rgb(ctx.ctx, ctx.acc.r, ctx.acc.g, ctx.acc.b)
        cairo.cairo_rectangle(ctx.ctx, x + 2, y + 2, w - 4, height - 4)
        cairo.cairo_stroke(ctx.ctx)

        -- Process keys
        local used = tonumber(state.used) or 0
        local cursorpos = tonumber(state.cursorpos) or 0
        if ctx.keycode == sdl_module.SDLK_LEFT then
            if cursorpos > 0 then
                state.cursorpos = cursorpos - 1
            end
        elseif ctx.keycode == sdl_module.SDLK_RIGHT then
            if cursorpos < used then
                state.cursorpos = cursorpos + 1
            end
        elseif ctx.keycode >= 0x20 and ctx.keycode <= 0x7e then
            local keycode = ctx.keycode
            -- Only upper-case ASCII letters when SHIFT/CAPS are active.
            if bit.band(ctx.mod, bit.bor(sdl_module.SDL_KMOD_LSHIFT, sdl_module.SDL_KMOD_CAPS)) ~= 0 then
                if keycode >= string.byte('a') and keycode <= string.byte('z') then
                    keycode = keycode - 32
                end
                -- Not mapping shifted punctuation (e.g. '!' for '1') to keep behavior predictable
                -- across keyboard layouts without a full keymap.
            end
            if keycode < 0 then keycode = 0 end
            if keycode > 127 then keycode = 127 end
            if cursorpos == used then
                state.data[used] = keycode
                state.used = used + 1
                state.cursorpos = cursorpos + 1
            elseif cursorpos < used then
                for m = used, cursorpos, -1 do
                    state.data[m + 1] = state.data[m]
                end
                state.data[cursorpos] = keycode
                state.cursorpos = cursorpos + 1
                state.used = used + 1
            end
        elseif ctx.keycode == sdl_module.SDLK_END then
            state.cursorpos = used
        elseif ctx.keycode == sdl_module.SDLK_HOME then
            state.cursorpos = 0
        elseif ctx.keycode == sdl_module.SDLK_BACKSPACE then
            if cursorpos > 0 and cursorpos <= used then
                for move = cursorpos - 1, used - 1 do
                    state.data[move] = state.data[move + 1]
                end
                state.data[used - 1] = 0
                state.used = used - 1
                state.cursorpos = cursorpos - 1
            end
        elseif ctx.keycode == sdl_module.SDLK_DELETE then
            if cursorpos >= 0 and cursorpos < used then
                for move = cursorpos, used - 1 do
                    state.data[move] = state.data[move + 1]
                end
                state.data[used - 1] = 0
                state.used = used - 1
            end
        end

        -- Calculate cursor position and adjust scroll (displaypos)
        local cum_off = 0.0
        local ext = ffi.new("cairo_text_extents_t")
        local cursor = tonumber(state.cursorpos) or 0
        local displaypos = tonumber(state.displaypos) or 0

        -- Calculate width from displaypos to cursor
        for j = displaypos, cursor - 1 do
            local str = string.char(state.data[j])
            cairo.cairo_text_extents(ctx.ctx, str, ext)
            cum_off = cum_off + ext.x_advance
        end

        -- Auto-scroll: adjust displaypos if cursor goes off-screen
        local visible_width = w - 2 * offset

        -- Scroll right if cursor is past the right edge
        while cum_off > visible_width and displaypos < cursor do
            local str = string.char(state.data[displaypos])
            cairo.cairo_text_extents(ctx.ctx, str, ext)
            cum_off = cum_off - ext.x_advance
            displaypos = displaypos + 1
        end

        -- Scroll left if cursor is before the left edge
        while cursor < displaypos and displaypos > 0 do
            displaypos = displaypos - 1
            local str = string.char(state.data[displaypos])
            cairo.cairo_text_extents(ctx.ctx, str, ext)
            cum_off = cum_off + ext.x_advance
        end

        state.displaypos = displaypos

        -- Recalculate cursor position from updated displaypos
        cum_off = 0.0
        for j = displaypos, cursor - 1 do
            local str = string.char(state.data[j])
            cairo.cairo_text_extents(ctx.ctx, str, ext)
            cum_off = cum_off + ext.x_advance
        end

        -- Draw cursor (with clipping to prevent overflow)
        cairo.cairo_save(ctx.ctx)
        cairo.cairo_new_path(ctx.ctx)
        cairo.cairo_rectangle(ctx.ctx, x + 2, y + 2, w - 4, height - 4)
        cairo.cairo_clip(ctx.ctx)

        cairo.cairo_new_path(ctx.ctx)
        cairo.cairo_set_source_rgb(ctx.ctx, ctx.acc.r, ctx.acc.g, ctx.acc.b)
        cairo.cairo_move_to(ctx.ctx, x + offset + cum_off, y + offset)
        cairo.cairo_rel_line_to(ctx.ctx, 0, m_height)
        cairo.cairo_stroke(ctx.ctx)

        cairo.cairo_restore(ctx.ctx)
    end

    -- Draw text (with clipping and scrolling)
    cairo.cairo_save(ctx.ctx)
    cairo.cairo_new_path(ctx.ctx)
    cairo.cairo_rectangle(ctx.ctx, x + 2, y + 2, w - 4, height - 4)
    cairo.cairo_clip(ctx.ctx)

    -- Draw only the visible portion starting from displaypos
    local displaypos = tonumber(state.displaypos) or 0
    local used = tonumber(state.used) or 0
    if used > displaypos then
        local visible_text = ffi.string(state.data + displaypos, used - displaypos)
        cairo.cairo_new_path(ctx.ctx)
        cairo.cairo_set_source_rgb(ctx.ctx, ctx.fg.r, ctx.fg.g, ctx.fg.b)
        -- Use m_height for consistent baseline instead of ext.height which varies
        cairo.cairo_move_to(ctx.ctx, x + offset, y + offset + m_height)
        cairo.cairo_show_text(ctx.ctx, visible_text)
    end

    cairo.cairo_restore(ctx.ctx)

    return rv
end

-- Export module
return {
    gui_context_new = gui_context_new,
    gui_editstate_new = gui_editstate_new,
    gui_begin = gui_begin,
    gui_end = gui_end,
    gui_theme_light = gui_theme_light,
    gui_theme_dark = gui_theme_dark,
    gui_process_events = gui_process_events,
    gui_label = gui_label,
    gui_button = gui_button,
    gui_checkbox = gui_checkbox,
    gui_radiobuttons = gui_radiobuttons,
    gui_colorsample = gui_colorsample,
    gui_slider = gui_slider,
    gui_ispinner = gui_ispinner,
    gui_editbox = gui_editbox,
}
