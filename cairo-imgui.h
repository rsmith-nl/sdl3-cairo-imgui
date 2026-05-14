// file: cairo-imgui.h
// vim:fileencoding=utf-8:ft=c:tabstop=2
// This is free and unencumbered software released into the public domain.
//
// Author: R.F. Smith <rsmith@xs4all.nl>
// SPDX-License-Identifier: Unlicense
// Created: 2025-08-26 12:57:19 +0200
// Last modified: 2026-05-15T00:43:02+0200

// Simple immediate mode GUI for SDL3 and Cairo.

#pragma once

#include <assert.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include <SDL3/SDL.h>
#include <cairo/cairo.h>

typedef struct {
  double r;
  double g;
  double b;
} GUI_rgb;

typedef struct {
  double x, y;
} GUI_vec2;

typedef struct {
  int x, y;
} GUI_veci2;

#define EBUF_SIZE 256
typedef struct {
  char data[EBUF_SIZE];
//  double cum_off[EBUF_SIZE];
  ptrdiff_t used;
  ptrdiff_t cursorpos;
  ptrdiff_t displaypos;
} GUI_editstate;

extern SDL_Renderer *renderer;
extern SDL_Texture *texture;

#ifdef __cplusplus
extern "C" {
#endif

// Some widgets need external state. This is provided by a pointer to external
// data named “state”.
// This data should either be a global, or should be “static” in the function
// that contains the GUI calls.

// All calls to GUI elements and all Cairo calls should *only* be done between
// gui_begin and gui_end;
void gui_begin(void);
void gui_end(void);

// Getters.
cairo_t *gui_get_context(void);

// Use theme color
void gui_use_fg(void);
void gui_use_bg(void);
void gui_use_acc(void);

// Retrieve input.
GUI_veci2 gui_get_mouse_pos(void);
bool gui_button_pressed(void);
int32_t gui_get_keycode(void);

// Call this to process events in SDL_AppEvent.
SDL_AppResult gui_process_events(SDL_Event *event);

// Theme helpers
void gui_theme_solarized_light(void);
void gui_theme_solarized_dark(void);

// Position helper.
// Transforms position from top left to bottom left.
GUI_vec2 gui_frombl(double x, double y);

// Show a button. Returns true when the button is pressed.
bool gui_button(GUI_vec2 left_top, char *label);

// Show a single line text.
void gui_label(double x, double y, char *label);

// Show a checkbox. Returns true when it is checked.
// Updates *state with the state of the checkbox.
bool gui_checkbox(double x, double y, char *label, bool *state);

// Show radio buttons. Return true if the selection has changed.
// Updates *state with the selected item.
bool gui_radiobuttons(double x, double y, int nlabels,
                      char *labels[nlabels], int *state);

// Show a color
void gui_colorsample(double x, double y,
                     double w, double h, GUI_rgb *state);

// Show a slider. This can have a value between 0 and 255.
// Returns true when the value has changed.
// The value is written to the variable “state”
bool gui_slider(double x, double y, int *state);

bool gui_ispinner(double x, double y,
                  int32_t min, int32_t max, int32_t*state);

bool gui_editbox(double x, double y, double w,
                 GUI_editstate *state);

// TODO:
// * spinner
// * edit field
// * list box
// * progress bar
// * image
//
// Optional
// * Add icons to buttons.
// * cycle button (same interface as radiobutton)
// * info bar (label with different background color)


#ifdef __cplusplus
}
#endif
