// file: circle-demo.c
// vim:fileencoding=utf-8:ft=c:tabstop=2
// This is free and unencumbered software released into the public domain.
//
// Author: R.F. Smith <rsmith@xs4all.nl>
// SPDX-License-Identifier: Unlicense
// Created: 2026-05-15 11:55:29 +0200
// Last modified: 2026-05-15T12:01:14+0200

#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <cairo/cairo.h>

#include "cairo-imgui.h"

#include <assert.h>
#include <stdio.h>
#include <math.h>

typedef struct {
  bool checked;
  int count;
} State;

static SDL_Window *window;

SDL_AppResult SDL_AppInit(void **appstate,
                          __attribute__((unused)) int argc,
                          __attribute__((unused)) char **argv)
{
  // Initialize state needed in all functions.
  static State s = {0};
  // Set a theme for the GUI.
  gui_theme_solarized_dark();
  // Make context available to other callbacks.
  *appstate = &s;
  if (!SDL_Init(SDL_INIT_VIDEO)) {
    SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
    return SDL_APP_FAILURE;
  }
  // The SDL_AppIterate callback should run ≈30× per second.
  SDL_SetHint(SDL_HINT_MAIN_CALLBACK_RATE, "30");
  // Create window and renderer.
  int w = 600;
  int h = 600;
  if (!SDL_CreateWindowAndRenderer("Cairo SDL3 IMGUI circle demo", w, h, 0,
                                   &window, &renderer)) {
    SDL_Log("Couldn't create a window and renderer: %s", SDL_GetError());
    return SDL_APP_FAILURE;
  }
  // Render on vsync to prevent tearing
  SDL_SetRenderVSync(renderer, SDL_RENDERER_VSYNC_ADAPTIVE);
  // Create texture for cairo to render to.
  texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
                              SDL_TEXTUREACCESS_STREAMING, w, h);
  return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void *appstate)
{
  State *s = appstate;
  // GUI definition starts here.
  gui_begin();
  // Close button
  if (gui_button(gui_frombl(10, 50), "Close")) {
    return SDL_APP_SUCCESS;
  }
  // Show cursor position to help with layout.
  gui_checkbox(gui_frombl(80, 40), "show mouse:", &s->checked);
  if (s->checked) {
    // Show cursor position to help with layout.
    char buf[80] = {0};
    GUI_veci2 mouse = gui_get_mouse_pos();
    snprintf(buf, 79, "x = %d, y = %d", mouse.x, mouse.y);
    gui_label(gui_frombl(210, 36), buf);
  }
  // Controls for circle
  gui_label((GUI_vec2) {10, 500}, "Segments");
  gui_hbar((GUI_vec2) {10, 520}, 60, &s->count);
  int segments = 4 + s->count;
  static char bseg[10] = {0};
  snprintf(bseg, 9, "%d", segments);
  gui_label((GUI_vec2) {100, 523}, bseg);
  // You can still draw here, between cairo_save and cairo_restore
  cairo_t *ctx = gui_get_context();
  cairo_save(ctx);
  int cx = 300, cy = 300, R = 240;
  cairo_new_path(ctx);
  cairo_set_source_rgba(ctx, 1.0, 0.5, 0.0, 1.0);
  cairo_arc(ctx, cx, cy, R, 0.0, M_PI);
  cairo_arc(ctx, cx, cy, R, M_PI, 2 * M_PI);
  cairo_stroke(ctx);
  cairo_new_path(ctx);
  gui_use_fg();
  double offset = M_PI / segments;
  double angle = offset;
  cairo_move_to(ctx, cx + R * cos(offset), cy + R * sin(offset));
  for (int j = 0; j < segments; j++) {
    angle -= 2 * M_PI / segments;
    double xto = cx + R * cos(angle);
    double yto = cy + R * sin(angle);
    cairo_line_to(ctx, xto, yto);
  }
  cairo_stroke(ctx);
  cairo_restore(ctx);
  // End of GUI definition
  gui_end();
  return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(__attribute__((unused)) void *appstate, SDL_Event *event)
{
  return gui_process_events(event);
}

void SDL_AppQuit(__attribute__((unused)) void *appstate, __attribute__((unused)) SDL_AppResult result)
{
  // Clean up.
  SDL_DestroyTexture(texture);
  SDL_DestroyWindow(window);
  SDL_DestroyRenderer(renderer);
}
