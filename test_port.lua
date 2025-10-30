#!/usr/bin/env luajit
-- test_port.lua
-- Validation test for the Lua port (no display needed)

local ffi = require("ffi")

print("=== Cairo ImGui Lua Port - Validation Test ===\n")

-- Test 1: Load modules
print("Test 1: Loading modules...")
local ok, sdl_module = pcall(require, "ffi_sdl3")
if not ok then
    print("  ❌ FAILED: ffi_sdl3.lua - " .. sdl_module)
    os.exit(1)
end
print("  ✓ ffi_sdl3.lua loaded")

local ok, cairo_module = pcall(require, "ffi_cairo")
if not ok then
    print("  ❌ FAILED: ffi_cairo.lua - " .. cairo_module)
    os.exit(1)
end
print("  ✓ ffi_cairo.lua loaded")

local ok, gui = pcall(require, "cairo_imgui")
if not ok then
    print("  ❌ FAILED: cairo_imgui.lua - " .. gui)
    os.exit(1)
end
print("  ✓ cairo_imgui.lua loaded")

-- Test 2: Check FFI constants
print("\nTest 2: Checking FFI constants...")
assert(sdl_module.SDL_INIT_VIDEO ~= nil, "SDL_INIT_VIDEO missing")
assert(sdl_module.SDL_PIXELFORMAT_ARGB8888 ~= nil, "SDL_PIXELFORMAT_ARGB8888 missing")
assert(cairo_module.CAIRO_FORMAT_ARGB32 ~= nil, "CAIRO_FORMAT_ARGB32 missing")
print("  ✓ All constants present")

-- Test 3: Create GUI context
print("\nTest 3: Creating GUI context...")
local ctx = gui.gui_context_new()
assert(ctx ~= nil, "GUI context creation failed")
assert(ctx.id == 1, "GUI context id incorrect")
assert(ctx.counter == 1, "GUI context counter incorrect")
print("  ✓ GUI context created successfully")
print("    - ID: " .. ctx.id)
print("    - Counter: " .. ctx.counter)

-- Test 4: Test theme functions
print("\nTest 4: Testing theme functions...")
gui.gui_theme_light(ctx)
assert(ctx.fg.r > 0.3 and ctx.fg.r < 0.4, "Light theme fg color incorrect")
print("  ✓ Light theme applied")
print(string.format("    - FG: %.3f, %.3f, %.3f", ctx.fg.r, ctx.fg.g, ctx.fg.b))

gui.gui_theme_dark(ctx)
assert(ctx.bg.r < 0.1, "Dark theme bg color incorrect")
print("  ✓ Dark theme applied")
print(string.format("    - BG: %.3f, %.3f, %.3f", ctx.bg.r, ctx.bg.g, ctx.bg.b))

-- Test 5: Create edit state
print("\nTest 5: Creating edit state...")
local editstate = gui.gui_editstate_new()
assert(editstate ~= nil, "Edit state creation failed")
assert(editstate.used == 0, "Edit state used incorrect")
assert(editstate.cursorpos == 0, "Edit state cursor incorrect")
print("  ✓ Edit state created successfully")
print("    - Used: " .. tonumber(editstate.used))
print("    - Cursor: " .. tonumber(editstate.cursorpos))

-- Test 6: Check library loading (will fail without libs, but that's OK)
print("\nTest 6: Checking library availability...")
local ok, err = pcall(function()
    return ffi.load("SDL3")
end)
if ok then
    print("  ✓ SDL3 library found")
else
    print("  ⚠ SDL3 library not found (expected in headless environment)")
    print("    " .. tostring(err))
end

local ok, err = pcall(function()
    return ffi.load("cairo")
end)
if ok then
    print("  ✓ Cairo library found")
else
    print("  ⚠ Cairo library not found (expected in headless environment)")
    print("    " .. tostring(err))
end

-- Test 7: Verify all widget functions exist
print("\nTest 7: Verifying widget functions...")
local widgets = {
    "gui_label",
    "gui_button",
    "gui_checkbox",
    "gui_radiobuttons",
    "gui_colorsample",
    "gui_slider",
    "gui_ispinner",
    "gui_editbox"
}

for _, widget in ipairs(widgets) do
    assert(gui[widget] ~= nil, widget .. " not found")
    assert(type(gui[widget]) == "function", widget .. " is not a function")
    print("  ✓ " .. widget)
end

-- Test 8: Verify helper functions
print("\nTest 8: Verifying helper functions...")
assert(gui.gui_begin ~= nil, "gui_begin not found")
assert(gui.gui_end ~= nil, "gui_end not found")
assert(gui.gui_process_events ~= nil, "gui_process_events not found")
assert(gui.gui_theme_light ~= nil, "gui_theme_light not found")
assert(gui.gui_theme_dark ~= nil, "gui_theme_dark not found")
print("  ✓ gui_begin")
print("  ✓ gui_end")
print("  ✓ gui_process_events")
print("  ✓ gui_theme_light")
print("  ✓ gui_theme_dark")

-- Final summary
print("\n" .. string.rep("=", 50))
print("✅ ALL TESTS PASSED!")
print(string.rep("=", 50))
print("\nValidation Summary:")
print("  • All modules load successfully")
print("  • FFI constants are defined correctly")
print("  • GUI context creation works")
print("  • Theme functions work")
print("  • Edit state creation works")
print("  • All 8 widgets are present")
print("  • All helper functions are present")
print("\n🎉 The Lua port is syntactically correct and ready!")
print("   (Note: Actual GUI testing requires a display environment)")
print()
