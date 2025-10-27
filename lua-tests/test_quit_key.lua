#!/usr/bin/env luajit
-- Test that ESC causes SDL_APP_SUCCESS via gui_process_events
-- Note: 'q' no longer quits to allow typing it in editbox
local ffi = require('ffi')
local sdlm = require('ffi_sdl3')
local gui = require('cairo_imgui')

local function assert_eq(a, b, msg)
    if a ~= b then
        io.stderr:write(string.format('[FAIL] %s (got=%s expected=%s)\n', msg or '', tostring(a), tostring(b)))
        os.exit(1)
    end
end

local ctx = gui.gui_context_new()
local ev = ffi.new('SDL_Event')

-- Helper to test key with type
local function check_key(event_type, keycode)
    ev.type = event_type
    ev.key.key = keycode
    ev.key.mod = 0
    local res = gui.gui_process_events(ctx, ev)
    return res
end

local SUCCESS = sdlm.SDL_APP_SUCCESS
local CONT = sdlm.SDL_APP_CONTINUE

-- 'q' and 'Q' should NOT quit (to allow typing in editbox)
assert_eq(check_key(sdlm.SDL_EVENT_KEY_DOWN, string.byte('q')), CONT, 'q KEY_DOWN should NOT quit')
assert_eq(check_key(sdlm.SDL_EVENT_KEY_UP, string.byte('q')), CONT, 'q KEY_UP should NOT quit')
assert_eq(check_key(sdlm.SDL_EVENT_KEY_DOWN, string.byte('Q')), CONT, 'Q KEY_DOWN should NOT quit')
assert_eq(check_key(sdlm.SDL_EVENT_KEY_UP, string.byte('Q')), CONT, 'Q KEY_UP should NOT quit')

-- ESC
assert_eq(check_key(sdlm.SDL_EVENT_KEY_DOWN, sdlm.SDLK_ESCAPE), SUCCESS, 'ESC KEY_DOWN should quit')
assert_eq(check_key(sdlm.SDL_EVENT_KEY_UP, sdlm.SDLK_ESCAPE), SUCCESS, 'ESC KEY_UP should quit')

-- Other key continues
assert_eq(check_key(sdlm.SDL_EVENT_KEY_DOWN, string.byte('a')), CONT, 'a KEY_DOWN should continue')
assert_eq(check_key(sdlm.SDL_EVENT_KEY_UP, string.byte('a')), CONT, 'a KEY_UP should continue')

print('[PASS] Quit key handling works: q/Q allowed for typing, ESC quits')
