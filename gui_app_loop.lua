-- gui_app_loop.lua
-- Reusable robust SDL3 + Cairo IMGUI app/event loop for LuaJIT
-- Encapsulates: startup settle, event draining, per-frame event cap, pacing
-- This is free and unencumbered software released into the public domain.

local M = {}

local ffi = require("ffi")
local sdlm = require("ffi_sdl3")
local sdl = sdlm.sdl

-- opts:
--   init(): bool            - initialize app (create ctx/window/renderer/texture)
--   iterate(): SDL_AppResult - render/update one frame (CONTINUE/SUCCESS/FAILURE)
--   on_event(event): SDL_AppResult - process a single SDL_Event
--   quit(): ()              - cleanup
--   options: table with fields:
--     target_fps (number, default 60)
--     startup_delay_ms (number, default 100)
--     startup_drain_cap (number, default 5000)
--     per_frame_event_cap (number, default 200)
--     yield_on_storm (bool, default true) -> SDL_Delay(1) if cap hit
--     set_callback_rate (number|string|nil, default "10") -> SDL_HINT_MAIN_CALLBACK_RATE
--     run_seconds (number|nil) optional auto-exit
--     log_frames (bool) optional console logging per frame
function M.run_loop(opts)
  assert(type(opts) == "table", "opts table required")
  local init = assert(opts.init, "opts.init required")
  local iterate = assert(opts.iterate, "opts.iterate required")
  local on_event = assert(opts.on_event, "opts.on_event required")
  local quit = assert(opts.quit, "opts.quit required")

  local o = opts.options or {}
  local TARGET_FPS = tonumber(o.target_fps) or 60
  if TARGET_FPS < 1 then TARGET_FPS = 60 end
  local FRAME_DELAY_MS = math.floor(1000 / TARGET_FPS)
  local STARTUP_DELAY_MS = tonumber(o.startup_delay_ms) or 100
  local STARTUP_DRAIN_CAP = tonumber(o.startup_drain_cap) or 5000
  local PER_FRAME_EVENT_CAP = tonumber(o.per_frame_event_cap) or 200
  local YIELD_ON_STORM = (o.yield_on_storm ~= false) -- default true
  local CALLBACK_RATE = (o.set_callback_rate == nil) and "10" or tostring(o.set_callback_rate)
  local RUN_SECONDS = tonumber(o.run_seconds or "")
  local LOG_FRAMES = o.log_frames == true

  if CALLBACK_RATE and CALLBACK_RATE ~= "" then
    sdl.SDL_SetHint(sdlm.SDL_HINT_MAIN_CALLBACK_RATE, CALLBACK_RATE)
  end

  if not init() then
    return sdlm.SDL_APP_FAILURE
  end

  -- Optional settle to avoid initial event storms causing starvation
  if STARTUP_DELAY_MS and STARTUP_DELAY_MS > 0 then
    sdl.SDL_Delay(STARTUP_DELAY_MS)
  end

  -- Drain startup events with a cap
  do
    local event = ffi.new("SDL_Event")
    local drained = 0
    while sdl.SDL_PollEvent(event) do
      drained = drained + 1
      if drained >= STARTUP_DRAIN_CAP then break end
    end
  end

  local event = ffi.new("SDL_Event")
  local running = true
  local frames = 0
  local deadline_ms = RUN_SECONDS and (sdlm.SDL_GetTicks() + RUN_SECONDS * 1000) or nil

  while running do
    -- Event pump with per-frame cap
    do
      local processed = 0
      while sdl.SDL_PollEvent(event) do
        local rc = on_event(event)
        if rc == sdlm.SDL_APP_SUCCESS or rc == sdlm.SDL_APP_FAILURE then
          running = false
          break
        end
        processed = processed + 1
        if processed >= PER_FRAME_EVENT_CAP then
          break
        end
      end
      if processed >= PER_FRAME_EVENT_CAP and YIELD_ON_STORM then
        sdl.SDL_Delay(1)
      end
    end
    if not running then break end

    -- Render/update one frame
    local rc = iterate()
    frames = frames + 1
    if LOG_FRAMES then
      io.stdout:write(string.format("[frame] %d\n", frames))
      io.stdout:flush()
    end
    if rc == sdlm.SDL_APP_SUCCESS or rc == sdlm.SDL_APP_FAILURE then
      running = false
      break
    end

    -- Auto-exit deadline
    if deadline_ms and sdlm.SDL_GetTicks() >= deadline_ms then
      running = false
      break
    end

    if FRAME_DELAY_MS > 0 then
      sdl.SDL_Delay(FRAME_DELAY_MS)
    end
  end

  quit()
  return sdlm.SDL_APP_SUCCESS
end

return M
