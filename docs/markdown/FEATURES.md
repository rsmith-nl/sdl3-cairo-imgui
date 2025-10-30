# Cairo ImGui - Current Features

**Last Updated**: October 27, 2025

This document describes all currently implemented features in the Cairo ImGui immediate-mode GUI toolkit for SDL3 and Cairo.

---

## Core Architecture

### Immediate Mode Design
- **No retained state**: Widgets are redrawn every frame
- **Direct Cairo rendering**: No command buffer abstraction
- **Frame-based updates**: All GUI state is transient between frames
- **Simple API**: Minimal function calls per widget

### Dual Implementation
- ✅ **C Implementation** (`cairo-imgui.c/h`) - Original reference implementation
- ✅ **Lua Port** (`cairo_imgui.lua`) - Full LuaJIT FFI port with feature parity

---

## Widget Library (8 Widgets)

### 1. Label (`gui_label`)
**Purpose**: Display static or dynamic text

**Features**:
- Text rendering with Cairo font engine
- Anti-aliased rendering
- Automatic text measurement
- Supports dynamic content (changes per frame)

**Parameters**:
- `x, y` - Position
- `label` - Text string

**Usage Example**:
```lua
gui.gui_label(ctx, 10, 20, "Hello World")
```

---

### 2. Button (`gui_button`)
**Purpose**: Clickable button with press detection

**Features**:
- ✅ Visual feedback (pressed/released states)
- ✅ Mouse hover detection
- ✅ Click-inside-only behavior (no drag-release from outside)
- ✅ Returns boolean: `true` on click, `false` otherwise
- ✅ Auto-sized based on label text
- ✅ Rounded corners (Cairo path)
- ✅ Theme-aware colors (fg/bg/accent)

**Parameters**:
- `x, y` - Top-left position
- `label` - Button text

**Return Value**:
- `true` if clicked (mouse pressed AND released inside)
- `false` otherwise

**Visual States**:
- Normal: Background color with border
- Hover: Highlighted background
- Pressed: Accent color background

**Known Behaviors**:
- Press must start inside button bounds
- Release outside button bounds cancels the click
- No keyboard activation (space/enter)

**Usage Example**:
```lua
if gui.gui_button(ctx, 50, 50, "Click Me") then
    print("Button was clicked!")
end
```

---

### 3. Checkbox (`gui_checkbox`)
**Purpose**: Toggle boolean state with visual indicator

**Features**:
- ✅ Toggle on click
- ✅ Visual checkmark when enabled
- ✅ Label text beside checkbox
- ✅ Returns new state value
- ✅ Click-inside-only behavior
- ✅ Theme-aware rendering

**Parameters**:
- `x, y` - Position
- `label` - Descriptive text
- `state` - Current boolean state (FFI bool array or Lua boolean)

**Return Value**:
- New state after interaction (toggles if clicked)

**Visual Elements**:
- Square checkbox (12x12 pixels)
- Checkmark (X shape) when checked
- Label text to the right

**Keyboard Support**:
- ✅ Space key toggles when hovered

**Usage Example**:
```lua
local checked = ffi.new("bool[1]", false)
checked[0] = gui.gui_checkbox(ctx, 10, 100, "Enable Feature", checked[0])
```

---

### 4. Radio Buttons (`gui_radiobuttons`)
**Purpose**: Select one option from multiple choices

**Features**:
- ✅ Vertical list of mutually exclusive options
- ✅ Filled circle indicates selected option
- ✅ Returns index of selected option (0-based)
- ✅ Click to select
- ✅ Keyboard navigation (Up/Down arrows when hovered)
- ✅ Left/Right arrow navigation (Left=previous, Right=next)
- ✅ Auto-spacing between options

**Parameters**:
- `x, y` - Top-left position
- `labels` - Table of option strings
- `state` - Current selected index (FFI int array or Lua number)

**Return Value**:
- Index of selected option (0-based)

**Visual Elements**:
- Circle (12px diameter) per option
- Filled circle for selected option
- Label text beside each circle
- Vertical spacing: 20 pixels between options

**Keyboard Support**:
- ✅ Up/Down arrow keys: Navigate options (wrap around)
- ✅ Left arrow: Previous option (wrap to last)
- ✅ Right arrow: Next option (wrap to first)

**Usage Example**:
```lua
local choice = ffi.new("int[1]", 0)
local options = {"Option A", "Option B", "Option C"}
choice[0] = gui.gui_radiobuttons(ctx, 10, 150, options, choice[0])
```

---

### 5. Color Sample (`gui_colorsample`)
**Purpose**: Display a color swatch (read-only)

**Features**:
- ✅ Rectangular color display
- ✅ No interaction (display-only)
- ✅ Custom width/height
- ✅ Border outline

**Parameters**:
- `x, y` - Position
- `w, h` - Width and height
- `rgb` - Color structure (GUI_rgb with r, g, b fields)

**Visual Elements**:
- Filled rectangle with specified color
- Black border outline

**Usage Example**:
```lua
local red = ffi.new("GUI_rgb", {r=1.0, g=0.0, b=0.0})
gui.gui_colorsample(ctx, 200, 50, 50, 30, red)
```

---

### 6. Slider (`gui_slider`)
**Purpose**: Select numeric value via draggable knob

**Features**:
- ✅ Horizontal track with draggable knob
- ✅ Value range: 0.0 to 100.0
- ✅ Value display label (centered, non-overlapping)
- ✅ Delta-based drag (no jump on grab)
- ✅ Continuous drag outside bounds
- ✅ Click track to reposition (immediate jump)
- ✅ Visual feedback (knob highlight on hover)

**Parameters**:
- `x, y` - Top-left position of track
- `state` - Pointer to float value (FFI float array)

**Return Value**:
- None (modifies state in-place)

**Dimensions**:
- Track: 200px wide × 20px tall
- Knob: 20px wide × 20px tall
- Label: Right-aligned at track end, vertically centered

**Interaction Modes**:
1. **Knob Drag**: Click knob, drag to adjust (delta-based, no jump)
2. **Track Click**: Click track, knob jumps to position immediately
3. **Drag Outside**: Continue dragging even when mouse leaves widget bounds

**Known Issues**:
- ⚠️ Intermittent "stuck" behavior (postponed investigation)
- ⚠️ No keyboard input (arrow keys, page up/down)
- ⚠️ No mouse wheel support

**Usage Example**:
```lua
local volume = ffi.new("float[1]", 50.0)
gui.gui_slider(ctx, 10, 200, volume)
print("Volume:", volume[0])
```

---

### 7. Integer Spinner (`gui_ispinner`)
**Purpose**: Integer input with increment/decrement buttons

**Features**:
- ✅ Value display with +/- buttons
- ✅ Min/max value clamping
- ✅ Click buttons to adjust
- ✅ Auto-sized based on digit count
- ✅ Immediate visual feedback

**Parameters**:
- `x, y` - Position
- `min, max` - Value range limits
- `state` - Pointer to integer value (FFI int array)

**Return Value**:
- None (modifies state in-place)

**Visual Elements**:
- Center: Current value (auto-sized width)
- Left: "-" button (decrease)
- Right: "+" button (increase)
- Borders around all sections

**Behavior**:
- Increment: `value = min(value + 1, max)`
- Decrement: `value = max(value - 1, min)`
- Wrapping: None (clamped to range)

**Known Limitations**:
- ⚠️ No keyboard input
- ⚠️ No mouse wheel support
- ⚠️ No click-and-hold repeat

**Usage Example**:
```lua
local count = ffi.new("int[1]", 5)
gui.gui_ispinner(ctx, 10, 250, 0, 10, count)
```

---

### 8. Text Edit Box (`gui_editbox`)
**Purpose**: Single-line text input field

**Features**:
- ✅ Text input with cursor
- ✅ Character insertion/deletion
- ✅ Cursor movement (Left/Right arrows, Home/End)
- ✅ Text selection and deletion (Backspace/Delete)
- ✅ Horizontal scrolling for overflow text
- ✅ Printable character input (ASCII 32-126)
- ✅ Keyboard modifiers (Shift for uppercase)
- ✅ Q/q typing works (special case handling)
- ✅ Shift+Digit for symbols (!@#$% etc.)

**Parameters**:
- `x, y` - Position
- `w` - Width in pixels
- `state` - GUI_editstate structure (data buffer, cursor, display position)

**Return Value**:
- None (modifies state in-place)

**Keyboard Support**:
- ✅ Printable characters: Insert at cursor
- ✅ Backspace: Delete character before cursor
- ✅ Delete: Delete character at cursor
- ✅ Left/Right arrows: Move cursor
- ✅ Home: Move to start
- ✅ End: Move to end
- ✅ Shift modifier: Uppercase and symbol input

**Visual Elements**:
- Border rectangle
- Text content (scrolls horizontally if needed)
- Cursor line (blinking, 1px wide)
- Padding: 2px inside border

**Buffer**:
- Max length: 256 bytes (255 chars + null terminator)
- Display scrolling when text exceeds width

**Known Behaviors**:
- ESC key works for quit (not captured by editbox)
- Q/q can be typed (doesn't trigger quit)
- Cursor position tracked independently of display scroll

**Usage Example**:
```lua
local editstate = gui.gui_editstate_new()
gui.gui_editbox(ctx, 10, 300, 200, editstate)
print("Input:", ffi.string(editstate.data))
```

---

## Theme System

### Theme Functions

#### `gui_theme_light(ctx)`
**Purpose**: Apply light color scheme

**Colors**:
- Foreground: `rgb(88, 110, 117)` - Dark gray-blue text
- Background: `rgb(253, 246, 227)` - Cream background
- Accent: `rgb(38, 139, 210)` - Blue highlights

---

#### `gui_theme_dark(ctx)`
**Purpose**: Apply dark color scheme

**Colors**:
- Foreground: `rgb(131, 148, 150)` - Light gray text
- Background: `rgb(7, 54, 66)` - Dark blue-gray background
- Accent: `rgb(42, 161, 152)` - Teal highlights

**Usage**:
```lua
gui.gui_theme_dark(ctx)  -- Switch to dark theme
```

---

## Event System

### `gui_process_events(ctx, event)`
**Purpose**: Process SDL events and update GUI context state

**Supported Events**:
- ✅ `SDL_EVENT_MOUSE_MOTION` - Track mouse position
- ✅ `SDL_EVENT_MOUSE_BUTTON_DOWN` - Button press
- ✅ `SDL_EVENT_MOUSE_BUTTON_UP` - Button release
- ✅ `SDL_EVENT_KEY_DOWN` - Keyboard input (keycode, modifiers)
- ✅ `SDL_EVENT_QUIT` - Application quit signal

**Context State Updated**:
- `mouse_x, mouse_y` - Current mouse coordinates
- `button_pressed` - Mouse button down this frame
- `button_released` - Mouse button up this frame
- `keycode` - Last key pressed (SDL keycode)
- `mod` - Keyboard modifiers (Shift, Ctrl, Alt)

**Event Flood Mitigation** (in demo/tests):
- Startup drain: Skip first 5000 events
- Per-frame cap: Process max 200 events
- Yield delay: 100ms delay before event loop

---

## Rendering System

### `gui_begin(renderer, texture, ctx)`
**Purpose**: Start GUI rendering frame

**Operations**:
1. Lock SDL texture for pixel access
2. Create Cairo surface mapping to texture pixels
3. Create Cairo rendering context
4. Fill background with theme color
5. Set default font size (14pt)
6. Reset widget counter

---

### `gui_end(ctx)`
**Purpose**: Finalize GUI rendering frame

**Operations**:
1. Destroy Cairo context
2. Destroy Cairo surface
3. Unlock SDL texture
4. Present texture to renderer

---

## Context Management

### `gui_context_new()`
**Purpose**: Create new GUI context

**Returns**: GUI_context structure with:
- Rendering state (renderer, texture, surface, cairo context)
- Input state (mouse, keyboard, button states)
- Theme colors (fg, bg, accent)
- Widget ID tracking (id, counter, maxid)

---

### `gui_editstate_new()`
**Purpose**: Create text edit state

**Returns**: GUI_editstate structure with:
- `data[256]` - Text buffer
- `used` - Current text length
- `cursorpos` - Cursor position in buffer
- `displaypos` - Horizontal scroll offset for display

---

## Testing Infrastructure

### Automated Tests (25 tests in `lua-tests/`)

**Widget Behavior Tests**:
- ✅ Button click behavior (inside-only)
- ✅ Button spacing and layout
- ✅ Checkbox toggle and space key
- ✅ Radio button navigation (up/down/left/right arrows)
- ✅ Slider drag mechanics and outside-bounds dragging
- ✅ Editbox text input, overflow, scrolling, modifiers

**System Tests**:
- ✅ SDL/Cairo minimal initialization
- ✅ Keyboard event handling
- ✅ Quit key handling (ESC vs Q)
- ✅ Tab focus cycling (planned feature validation)
- ✅ Lua/C parity verification

**Interactive Tests**:
- ✅ Slider drag (auto-exit, visual feedback)
- ✅ Editbox baseline alignment

**Validation**:
- ✅ `test_port.lua` - Headless module validation
- ✅ All widgets, themes, and helpers verified

---

## Demo Application

### `demo.lua` / `cairo-imgui-demo.c`
**Purpose**: Showcase all widgets and features

**Features**:
- ✅ All 8 widgets demonstrated
- ✅ Theme switcher (Light/Dark via radio buttons)
- ✅ Frame rate control (60 FPS default, configurable via `IMGUI_FPS`)
- ✅ Auto-exit mode (`IMGUI_RUN_SECONDS` env var)
- ✅ Event flood protection
- ✅ Live interaction with all widgets

**Environment Variables**:
- `IMGUI_FPS=30` - Set target frame rate
- `IMGUI_RUN_SECONDS=5` - Auto-exit after N seconds
- `IMGUI_LOG_FRAMES=1` - Log each frame number
- `IMGUI_DEBUG_EVENTS=1` - Log event processing
- `IMGUI_DEBUG_BUTTONS=1` - Log button state changes

**Usage**:
```bash
luajit demo.lua
IMGUI_FPS=30 IMGUI_RUN_SECONDS=3 luajit demo.lua
```

---

## Platform Support

### Supported Platforms
- ✅ **Linux** (primary development, Debian 12 + KDE)
- ✅ **Windows 11** (MinGW64/MSYS2 build, tested in Wine)
- ⚠️ **macOS** (untested, should work with SDL3/Cairo installed)

### Build Systems
- ✅ **Make** - C implementation (`make`)
- ✅ **MinGW64/MSYS2** - Windows cross-compilation
- ✅ **Direct execution** - Lua port (no build needed, `luajit demo.lua`)

---

## Dependencies

### C Implementation
- **SDL3** - Window, rendering, events (libSDL3-dev)
- **Cairo** - Vector graphics rendering (libcairo2-dev)
- **C11 compiler** - Clang or GCC

### Lua Port
- **LuaJIT** - Lua runtime with FFI
- **SDL3** - Dynamic library (libSDL3.so / SDL3.dll)
- **Cairo** - Dynamic library (libcairo.so.2 / cairo.dll)
- **Lua modules**:
  - `ffi_sdl3.lua` - SDL3 FFI bindings
  - `ffi_cairo.lua` - Cairo FFI bindings
  - `cairo_imgui.lua` - GUI implementation

---

## API Conventions

### Immediate Mode Pattern
```lua
while running do
    gui.gui_begin(renderer, texture, ctx)
    
    -- Widgets are called every frame
    if gui.gui_button(ctx, 10, 10, "Click") then
        print("Clicked!")
    end
    
    gui.gui_end(ctx)
end
```

### State Management
- **Caller owns state**: Application maintains widget state (checkboxes, sliders, etc.)
- **No hidden state**: All state is explicit in function parameters
- **Stateless widgets**: Widgets don't remember previous frames (except drag tracking)

### Coordinate System
- **Origin**: Top-left (0, 0)
- **X-axis**: Increases to the right
- **Y-axis**: Increases downward
- **Units**: Pixels
- **No layout engine**: Static positioning only

---

## Performance Characteristics

### Frame Rate
- **Target**: 60 FPS default
- **Configurable**: Via `IMGUI_FPS` environment variable
- **Frame pacing**: SDL_Delay for consistent timing

### Rendering
- **Full redraw**: Every frame redraws entire GUI
- **Cairo anti-aliasing**: Smooth edges on all shapes
- **Texture streaming**: SDL texture updated per frame

### Memory
- **No allocations per frame**: All state pre-allocated
- **Fixed buffers**: Editbox 256 bytes, no dynamic growth
- **Immediate mode**: No retained scene graph

---

## Known Limitations (See MISSING_FEATURES.md)

This section lists limitations that are **by design** or **postponed**:

1. **No keyboard focus system** - Hover-only interaction
2. **No layout engine** - Static positioning required
3. **No widget nesting** - Flat widget hierarchy
4. **No command buffer** - Direct rendering only
5. **Single-line editbox** - No multi-line text
6. **No scrollable containers** - Fixed viewport
7. **No tooltips** - No hover help text
8. **No drag-and-drop** - No inter-widget dragging

See [MISSING_FEATURES.md](MISSING_FEATURES.md) for complete list and future roadmap.

---

## Documentation Files

- **FEATURES.md** (this file) - Current implemented features
- **MISSING_FEATURES.md** - Planned features and limitations
- **README_LUA_PORT.md** - Lua port technical details
- **PORT_SUMMARY.md** - Metrics and analysis
- **CHANGELOG.md** - Version history
- **README.rst** - Main project overview

---

**Note**: This is a minimal immediate-mode GUI toolkit focused on simplicity. Many "missing" features are intentionally excluded to maintain the lightweight, easy-to-understand codebase.
