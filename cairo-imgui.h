// file: cairo-imgui.h
// vim:fileencoding=utf-8:ft=c:tabstop=2
// This is free and unencumbered software released into the public domain.
//
// Author: R.F. Smith <rsmith@xs4all.nl>
// SPDX-License-Identifier: Unlicense
// Created: 2025-08-26 12:57:19 +0200
// Last modified: 2025-08-27T19:26:24+0200

// Simple immediate mode GUI for SDL3 and Cairo.

#pragma once

#include <assert.h>
#include <stdbool.h>
#include <stdint.h>

#include <SDL3/SDL.h>
#include <cairo/cairo.h>

typedef struct {
  double r;
  double g;
  double b;
} GUI_rgb;

typedef struct {
  SDL_Renderer *renderer;
  SDL_Texture *texture;
  cairo_surface_t *surface;
  cairo_t *ctx;
  int32_t mouse_x, mouse_y;
  int32_t keycode;
  int16_t mod;
  bool button_pressed;
  bool button_released;
  GUI_rgb fg;
  GUI_rgb bg;
  GUI_rgb acc;
} GUI_context;

#ifdef __cplusplus
extern "C" {
#endif

// All calls to GUI elements and all Cairo calls should *only* be done between
// gui_begin and gui_end;
void gui_begin(SDL_Renderer *renderer, SDL_Texture *texture, GUI_context *out);
void gui_end(GUI_context *ctx);

// Call this to process events in SDL_AppEvent.
SDL_AppResult gui_process_events(GUI_context *ctx, SDL_Event *event);

// Theme helpers
void gui_theme_light(GUI_context *ctx);
void gui_theme_dark(GUI_context *ctx);

// Show a button. Returns true when the button is pressed.
bool gui_button(GUI_context *c, double x, double y, const char *label);

// Show a single line text.
void gui_label(GUI_context *c, double x, double y, const char *label);

// Show a checkbox. Returns true when it is checked.
// Updates *state with the state of the checkbox.
bool gui_checkbox(GUI_context *c, double x, double y, const char *label, bool *state);

// Show radio buttons. Return true if the selection has changed.
// Updates *state with the selected item.
bool gui_radiobuttons(GUI_context *c, double x, double y, int nlabels,
                      const char *labels[nlabels], int *state);

// Show a color
void gui_colorsample(GUI_context *c, const double x, const double y,
                     const double w, const double h, const GUI_rgb *color);

// Show a slider. This can have a value between 0 and 255.
// Returns true when the value has changed.
bool gui_slider(GUI_context *c, const double x, const double y, int *value);

#ifdef __cplusplus
}
#endif
