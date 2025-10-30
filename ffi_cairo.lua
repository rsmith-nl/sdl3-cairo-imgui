-- ffi_cairo.lua
-- LuaJIT FFI bindings for Cairo graphics library
-- This is free and unencumbered software released into the public domain.

local ffi = require("ffi")

-- Cairo type definitions and function declarations
ffi.cdef [[
// Opaque types
typedef struct _cairo cairo_t;
typedef struct _cairo_surface cairo_surface_t;

// Enums
typedef enum {
    CAIRO_FORMAT_INVALID   = -1,
    CAIRO_FORMAT_ARGB32    = 0,
    CAIRO_FORMAT_RGB24     = 1,
    CAIRO_FORMAT_A8        = 2,
    CAIRO_FORMAT_A1        = 3,
    CAIRO_FORMAT_RGB16_565 = 4,
    CAIRO_FORMAT_RGB30     = 5
} cairo_format_t;

typedef enum {
    CAIRO_STATUS_SUCCESS = 0
} cairo_status_t;

// Text extents structure
typedef struct {
    double x_bearing;
    double y_bearing;
    double width;
    double height;
    double x_advance;
    double y_advance;
} cairo_text_extents_t;

// Surface functions
cairo_surface_t* cairo_image_surface_create_for_data(
    unsigned char* data,
    cairo_format_t format,
    int width,
    int height,
    int stride
);

cairo_status_t cairo_surface_status(cairo_surface_t* surface);
void cairo_surface_flush(cairo_surface_t* surface);
void cairo_surface_mark_dirty(cairo_surface_t* surface);
void cairo_surface_destroy(cairo_surface_t* surface);
cairo_status_t cairo_surface_status(cairo_surface_t* surface);

// Context functions
cairo_t* cairo_create(cairo_surface_t* target);
void cairo_destroy(cairo_t* cr);
cairo_status_t cairo_status(cairo_t* cr);

// Drawing operations
void cairo_paint(cairo_t* cr);
void cairo_stroke(cairo_t* cr);
void cairo_fill(cairo_t* cr);

// Path operations
void cairo_new_path(cairo_t* cr);
void cairo_close_path(cairo_t* cr);
void cairo_move_to(cairo_t* cr, double x, double y);
void cairo_line_to(cairo_t* cr, double x, double y);
void cairo_rel_move_to(cairo_t* cr, double dx, double dy);
void cairo_rel_line_to(cairo_t* cr, double dx, double dy);
void cairo_rectangle(cairo_t* cr, double x, double y, double width, double height);
void cairo_arc(cairo_t* cr, double xc, double yc, double radius, double angle1, double angle2);

// Color/source operations
void cairo_set_source_rgb(cairo_t* cr, double red, double green, double blue);
void cairo_set_source_rgba(cairo_t* cr, double red, double green, double blue, double alpha);

// Line width
void cairo_set_line_width(cairo_t* cr, double width);

// Text operations
void cairo_select_font_face(cairo_t* cr, const char* family, int slant, int weight);
void cairo_set_font_size(cairo_t* cr, double size);
void cairo_text_extents(cairo_t* cr, const char* utf8, cairo_text_extents_t* extents);
void cairo_show_text(cairo_t* cr, const char* utf8);

// Transformation operations (if needed)
void cairo_save(cairo_t* cr);
void cairo_restore(cairo_t* cr);
void cairo_translate(cairo_t* cr, double tx, double ty);
void cairo_scale(cairo_t* cr, double sx, double sy);
void cairo_rotate(cairo_t* cr, double angle);

// Clipping operations
void cairo_clip(cairo_t* cr);
void cairo_clip_preserve(cairo_t* cr);
void cairo_reset_clip(cairo_t* cr);
]]

-- Load Cairo library
local cairo = ffi.load("cairo")

-- Export module
return {
    cairo = cairo,
    ffi = ffi,

    -- Format constants
    CAIRO_FORMAT_ARGB32 = ffi.C.CAIRO_FORMAT_ARGB32,
    CAIRO_FORMAT_RGB24 = ffi.C.CAIRO_FORMAT_RGB24,
}
