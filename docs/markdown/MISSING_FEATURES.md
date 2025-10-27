# Cairo ImGui - Missing Features & Future Roadmap

**Last Updated**: October 27, 2025

This document catalogs features that are **not yet implemented**, **intentionally excluded**, or **postponed** in the Cairo ImGui immediate-mode GUI toolkit.

---

## Philosophy: Intentional Simplicity

Many "missing" features are **by design**. The project goals are:
1. **Keep it simple** - Easy to understand, minimal code
2. **Immediate mode focus** - No retained state, direct rendering
3. **Static layout** - No complex layout engines
4. **Proof of concept** - Demonstrate SDL3 + Cairo integration

Therefore, some features are **intentionally excluded** to maintain simplicity.

---

## Categories

- 🔴 **Not Planned** - By design, excluded to maintain simplicity
- 🟡 **Postponed** - Feasible but deferred, may implement later
- 🟢 **Planned** - Actively considering, likely to implement
- ⚪ **Under Consideration** - Evaluating feasibility/value

---

## Widget Enhancements

### Button Widget

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| Keyboard activation (Space/Enter) | 🟡 Postponed | Low | Requires focus system |
| Icon support | 🔴 Not Planned | - | Use custom drawing instead |
| Disabled state | 🟢 Planned | Medium | Visual-only, no interaction |
| Toggle button | ⚪ Considering | Low | Checkbox covers this use case |
| Multi-line text | 🔴 Not Planned | - | Keep simple, single-line only |
| Custom button sizes | 🟢 Planned | Low | Add width/height parameters |
| Button groups | 🔴 Not Planned | - | Manual layout, not automatic |

---

### Slider Widget

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| **Fix intermittent "stuck" behavior** | 🟡 Postponed | High | Known issue, needs investigation |
| Keyboard input (arrow keys) | 🟡 Postponed | Medium | Requires focus system |
| Mouse wheel support | 🟡 Postponed | Medium | Nice-to-have for value adjustment |
| Vertical orientation | ⚪ Considering | Low | Horizontal-only currently |
| Configurable range (not 0-100) | 🟢 Planned | High | Add min/max parameters |
| Step/snap values | 🟢 Planned | Low | E.g., snap to multiples of 5 |
| Value tooltip on drag | ⚪ Considering | Low | Extra visual feedback |
| Track markers/ticks | 🔴 Not Planned | - | Visual clutter |
| Page-step on track click | ⚪ Considering | Low | Alternative to jump-to-cursor |
| Logarithmic scale | 🔴 Not Planned | - | Linear only for simplicity |
| Range slider (two knobs) | 🔴 Not Planned | - | Too complex |

**Postponed Investigation**:
- Delta-based drag occasionally gets "stuck" at various positions
- Need debug traces for drag lifecycle
- Minimal repro scenario with single slider

---

### Integer Spinner

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| Keyboard input (type value) | 🟡 Postponed | Medium | Requires text input handling |
| Mouse wheel support | 🟢 Planned | High | Natural interaction |
| Click-and-hold repeat | 🟢 Planned | Medium | Faster value changes |
| Step size configuration | 🟢 Planned | Low | Currently fixed at ±1 |
| Float spinner variant | ⚪ Considering | Low | Use slider for floats |
| Wraparound mode | 🔴 Not Planned | - | Clamp-only is clearer |

---

### Editbox Widget

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| Multi-line text | 🔴 Not Planned | - | Single-line by design |
| Text selection (mouse drag) | 🟡 Postponed | Medium | Copy/paste prerequisite |
| Copy/paste (Ctrl+C/V) | 🟡 Postponed | Low | Platform clipboard integration |
| Undo/redo | 🔴 Not Planned | - | Too complex for simple toolkit |
| Word navigation (Ctrl+Arrow) | 🟡 Postponed | Low | Nice-to-have |
| Double-click word selection | 🟡 Postponed | Low | Nice-to-have |
| Input validation | ⚪ Considering | Low | App-level responsibility |
| Placeholder text | 🟢 Planned | Low | "Type here..." hint |
| Password masking | ⚪ Considering | Low | Show dots instead of text |
| Character limit indicator | 🔴 Not Planned | - | 256 char max is fixed |
| Auto-complete | 🔴 Not Planned | - | Too complex |
| Rich text formatting | 🔴 Not Planned | - | Plain text only |

---

### Checkbox Widget

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| Tri-state (checked/unchecked/indeterminate) | 🔴 Not Planned | - | Binary only |
| Custom check styles | 🔴 Not Planned | - | Keep consistent |
| Disabled state | 🟢 Planned | Low | Visual-only |

---

### Radio Buttons

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| Horizontal layout | ⚪ Considering | Low | Currently vertical-only |
| Custom spacing | 🟢 Planned | Low | Fixed 20px currently |
| Icons instead of text | 🔴 Not Planned | - | Text-only |
| Disabled options | 🟢 Planned | Low | Visual-only |

---

### Color Sample

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| Color picker dialog | 🔴 Not Planned | - | Read-only display widget |
| Click to copy color | 🔴 Not Planned | - | Read-only by design |
| Transparency/alpha support | ⚪ Considering | Low | RGB-only currently |

---

### Label Widget

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| Text alignment (center/right) | 🟢 Planned | Low | Left-aligned only |
| Word wrapping | 🔴 Not Planned | - | Single-line only |
| Rich text / markdown | 🔴 Not Planned | - | Plain text only |
| Selectable text | 🔴 Not Planned | - | Static display |

---

## New Widgets

| Widget | Status | Priority | Notes |
|--------|--------|----------|-------|
| **Dropdown / Combo Box** | ⚪ Considering | Medium | Select from list |
| **List Box** | 🔴 Not Planned | - | Too complex |
| **Scrollbar** | 🔴 Not Planned | - | No scrollable containers |
| **Progress Bar** | 🟢 Planned | Medium | Simple value display |
| **Tooltip** | 🟡 Postponed | Low | Hover text helper |
| **Menu Bar** | 🔴 Not Planned | - | Too complex |
| **Context Menu** | 🔴 Not Planned | - | Too complex |
| **Tab Control** | 🔴 Not Planned | - | Manual layout instead |
| **Tree View** | 🔴 Not Planned | - | Too complex |
| **Table / Grid** | 🔴 Not Planned | - | Too complex |
| **Image Widget** | ⚪ Considering | Low | Display Cairo surface |
| **Separator Line** | 🟢 Planned | Low | Visual grouping |
| **Group Box** | 🟢 Planned | Low | Border + title |
| **Icon Button** | 🔴 Not Planned | - | Custom drawing |

---

## Layout & Positioning

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| **Layout engine** | 🔴 Not Planned | - | Static positioning by design |
| **Auto-layout (flexbox, grid)** | 🔴 Not Planned | - | Manual layout only |
| **Anchoring / docking** | 🔴 Not Planned | - | Fixed coordinates |
| **Responsive sizing** | 🔴 Not Planned | - | Fixed window size |
| **Scrollable containers** | 🔴 Not Planned | - | No viewport management |
| **Widget nesting** | 🔴 Not Planned | - | Flat hierarchy only |
| **Z-order / layering** | 🔴 Not Planned | - | Draw order is code order |
| **Clipping regions** | 🟡 Postponed | Low | Cairo supports this |
| **Helper: Column layout** | 🟢 Planned | Medium | Simple multi-column helper |
| **Helper: Grid layout** | 🟢 Planned | Low | Simple grid positioning |

---

## Input & Interaction

### Keyboard Focus System

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| **Tab navigation** | 🟡 Postponed | High | Test exists, not implemented |
| **Visual focus indicator** | 🟡 Postponed | High | Requires focus system |
| **Programmatic focus** | 🟡 Postponed | Medium | `set_focus(widget_id)` |
| **Focus traversal order** | 🟡 Postponed | Low | Custom tab order |
| **Escape to unfocus** | 🟡 Postponed | Low | Clear active widget |

**Current State**: Hover-only interaction, no persistent focus

**Blocked Features**:
- Keyboard activation of buttons
- Arrow key navigation without hover
- Tab key to cycle through widgets

---

### Mouse Interaction

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| **Double-click detection** | 🟡 Postponed | Low | Timing-based |
| **Right-click context menus** | 🔴 Not Planned | - | Too complex |
| **Drag-and-drop** | 🔴 Not Planned | - | No inter-widget dragging |
| **Mouse cursor changes** | ⚪ Considering | Low | Resize, hand, etc. |
| **Hover tooltips** | 🟡 Postponed | Low | Delayed popup on hover |
| **Long press detection** | 🔴 Not Planned | - | Mobile-focused |

---

### Keyboard Shortcuts

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| **Ctrl+Q to quit** | ⚪ Considering | Low | Currently ESC only |
| **Ctrl+C/V clipboard** | 🟡 Postponed | Low | For editbox |
| **Mnemonics (Alt+letter)** | 🔴 Not Planned | - | No menu system |
| **Custom key bindings** | 🔴 Not Planned | - | App-level responsibility |

---

## Rendering & Visuals

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| **Custom fonts** | 🟡 Postponed | Low | Fixed 14pt default |
| **Font size control** | 🟡 Postponed | Low | Per-widget or global |
| **Bold/italic text** | 🔴 Not Planned | - | Single font style |
| **Custom colors per widget** | 🟡 Postponed | Medium | Override theme colors |
| **Gradients** | 🔴 Not Planned | - | Solid colors only |
| **Shadows** | 🔴 Not Planned | - | Visual complexity |
| **Animations** | 🔴 Not Planned | - | Immediate mode, no tweening |
| **Transparency/opacity** | ⚪ Considering | Low | Cairo supports alpha |
| **Custom drawing callback** | 🟢 Planned | Medium | User-provided render func |
| **SVG icons** | 🔴 Not Planned | - | Use Cairo directly |
| **Texture/image support** | ⚪ Considering | Low | Load Cairo surface |

---

## Themes

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| **More built-in themes** | 🟢 Planned | Low | Currently: light, dark |
| **Custom theme creation** | 🟢 Planned | Low | User-defined color schemes |
| **Per-widget theme override** | 🟡 Postponed | Low | Currently global only |
| **Theme hot-reload** | 🔴 Not Planned | - | Restart required |
| **Theme presets (solarized, etc)** | ⚪ Considering | Low | Community contributions |

---

## Platform & Integration

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| **macOS testing** | 🟡 Postponed | Medium | Untested, should work |
| **Web (WASM) port** | 🔴 Not Planned | - | SDL3 WASM support unclear |
| **Mobile (Android/iOS)** | 🔴 Not Planned | - | Desktop-focused |
| **High-DPI / Retina support** | ⚪ Considering | Medium | Cairo handles scaling |
| **Multiple windows** | 🔴 Not Planned | - | Single window only |
| **Custom window decorations** | 🔴 Not Planned | - | SDL3 default |
| **Fullscreen mode** | ⚪ Considering | Low | SDL3 supports this |

---

## Accessibility

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| **Screen reader support** | 🔴 Not Planned | - | No accessibility API |
| **High contrast mode** | 🟢 Planned | Low | Theme variant |
| **Keyboard-only navigation** | 🟡 Postponed | Medium | Needs focus system |
| **Configurable font sizes** | 🟡 Postponed | Low | Fixed 14pt currently |
| **Colorblind modes** | 🔴 Not Planned | - | Theme responsibility |

---

## Performance & Optimization

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| **Widget culling** | 🔴 Not Planned | - | Draw all, every frame |
| **Dirty region tracking** | 🔴 Not Planned | - | Full redraw by design |
| **GPU acceleration** | ⚪ Considering | Low | Cairo can use GL backend |
| **Retained mode option** | 🔴 Not Planned | - | Immediate mode by design |
| **Multi-threading** | 🔴 Not Planned | - | Single-threaded |
| **Draw call batching** | 🔴 Not Planned | - | Cairo handles this |

---

## Developer Experience

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| **Debug overlay** | 🟢 Planned | Medium | Show widget bounds, IDs |
| **Widget inspector** | 🟡 Postponed | Low | Hover to show info |
| **Performance metrics** | 🟢 Planned | Low | FPS, draw time |
| **Error handling** | ⚪ Considering | Medium | Asserts vs graceful fallback |
| **Logging system** | 🟢 Planned | Low | Debug output control |
| **API documentation** | 🟢 Planned | High | Doxygen or similar |
| **More examples** | 🟢 Planned | Medium | Widget showcase apps |
| **Tutorial series** | 🟡 Postponed | Low | Step-by-step guides |

---

## Testing

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| **Visual regression tests** | 🟡 Postponed | Low | Screenshot comparison |
| **Benchmarking suite** | 🟡 Postponed | Low | Performance tracking |
| **Fuzzing** | 🔴 Not Planned | - | Overkill for this project |
| **CI/CD pipeline** | 🟢 Planned | Medium | Automated test runs |
| **Cross-platform testing** | 🟡 Postponed | Medium | Linux/Windows/macOS |

---

## Known Bugs & Issues

### High Priority

1. **Slider "stuck" behavior** (🟡 Postponed)
   - Symptom: Knob intermittently freezes at various positions
   - Cause: Unknown, delta-based drag or event batching issue
   - Workaround: Release and re-grab knob
   - Status: Postponed for further investigation

### Medium Priority

2. **Event flood on startup** (✅ Mitigated)
   - Symptom: Frozen window on launch
   - Cause: SDL3 event queue overload
   - Solution: Drain 5000 events, cap 200/frame, 100ms delay
   - Status: Fixed with workarounds

### Low Priority

3. **Editbox cursor blinking not synced to frame rate**
   - Symptom: Cursor blink rate is fixed, not frame-dependent
   - Impact: Low, purely visual
   - Status: Accepted limitation

---

## Feature Requests from Community

*(Placeholder - no community yet, project is new)*

To request a feature:
1. Check if it's already listed here (Planned/Considering/Not Planned)
2. If "Not Planned", understand it's by design (simplicity goal)
3. If missing, open a GitHub issue with:
   - Use case description
   - Why existing widgets can't solve it
   - Proposed API (optional)

---

## Roadmap Priority

### Phase 1: Core Stability (Current)
- ✅ Fix slider drag bugs → 🟡 Postponed (partial fix)
- ✅ Complete Lua port
- ✅ Comprehensive testing
- ✅ Documentation

### Phase 2: Essential Enhancements
- 🟢 Configurable slider range (min/max parameters)
- 🟢 Mouse wheel support for spinner
- 🟢 Click-and-hold repeat for spinner
- 🟢 Progress bar widget
- 🟢 Separator line widget
- 🟢 Debug overlay

### Phase 3: Polish & UX
- 🟡 Keyboard focus system (tab navigation)
- 🟡 Tooltip support
- 🟡 Custom colors per widget
- 🟡 More theme presets
- 🟡 High-DPI support

### Phase 4: Advanced (Future)
- ⚪ Dropdown/combo box widget
- ⚪ Custom drawing callbacks
- ⚪ Image/texture widget
- ⚪ Grid/column layout helpers
- ⚪ macOS testing

### Not Planned (By Design)
- 🔴 Layout engine
- 🔴 Retained mode
- 🔴 Complex widgets (tree, table, menu)
- 🔴 Drag-and-drop
- 🔴 Animations
- 🔴 Multi-line editbox

---

## Contributing

If you'd like to implement a **🟢 Planned** or **⚪ Considering** feature:

1. **Check current status** - Feature may be in progress
2. **Open an issue first** - Discuss approach before coding
3. **Keep it simple** - Follow project philosophy
4. **Test thoroughly** - Include automated tests
5. **Document well** - Update this file and FEATURES.md

**Guidelines**:
- Maintain immediate-mode design
- No external dependencies beyond SDL3/Cairo
- Keep API minimal and consistent
- Preserve simplicity (avoid feature creep)

---

## Why Not Implemented?

### Design Constraints

**"Why no layout engine?"**
- Immediate mode benefits from explicit positioning
- Auto-layout adds significant complexity
- Static layouts are predictable and debuggable

**"Why no retained mode option?"**
- Project goal is immediate-mode proof-of-concept
- Retained mode is a completely different architecture
- Use other toolkits (Qt, GTK) for retained mode

**"Why no keyboard focus?"**
- Adds state management complexity
- Hover-based interaction is simpler
- Deferred to Phase 3 (not a blocker for basic use)

**"Why no rich text?"**
- Complex text layout requires dedicated library
- Cairo text API is basic by design
- Use Pango or similar if needed (external dependency)

---

## Alternatives for Missing Features

If you need features marked **🔴 Not Planned**:

- **Layout engine** → Use [Dear ImGui](https://github.com/ocornut/imgui), [Nuklear](https://github.com/Immediate-Mode-UI/Nuklear)
- **Complex widgets** → Use [Qt](https://www.qt.io/), [GTK](https://www.gtk.org/)
- **Retained mode** → Use traditional GUI toolkits
- **Web/mobile** → Use web frameworks or native toolkits
- **Rich text** → Integrate [Pango](https://pango.gnome.org/)

**This toolkit is for**:
- Simple tools and utilities
- Learning immediate-mode GUI concepts
- Prototyping with SDL3 + Cairo
- Lightweight desktop apps

**This toolkit is NOT for**:
- Complex production applications
- Mobile/web apps
- Rich document editing
- AAA game UI (use specialized game UI libs)

---

## Version History

- **2025-10-27**: Initial missing features documentation
- Future updates will track implemented features moving from this file to FEATURES.md

---

**Philosophy**: A small, simple, well-documented toolkit is better than a large, complex, poorly-understood one. Not every feature needs to exist in every library.
