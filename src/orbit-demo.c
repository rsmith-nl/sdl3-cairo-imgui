// file: orbit-demo.c
// vim:fileencoding=utf-8:ft=c:tabstop=2
// This is free and unencumbered software released into the public domain.
///
// Inspired by: https://www.youtube.com/watch?v=nCg3aXn5F3M
// “The Code That Revolutionized Orbital Simulation” by https://www.youtube.com/@braintruffle
//
// Author: R.F. Smith <rsmith@xs4all.nl>
// SPDX-License-Identifier: Unlicense
// Created: 2026-05-15 14:25:59 +0200
// Last modified: 2026-05-15T15:23:21+0200

#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <cairo/cairo.h>

#include "cairo-imgui.h"

#include <assert.h>
#include <stdio.h>
#include <math.h>

#define SCALE 200.0

typedef struct {
  double x, y;
} Vec2;

typedef struct {
  Vec2 pos, vel, acc;
  double dev, maxdev;
  bool run;
} Simulation;

inline static double len(Vec2 v)
{
  return sqrt(v.x * v.x + v.y * v.y);
}

void reset(Simulation *s)
{
  s->run = false;
  s->pos.x = 1.0;
  s->pos.y = 0.0;
  s->vel.x = 0.13;  // Velocities tuned
  s->vel.y = 0.991; // for reduced error.
  s->dev = 0.0;
  s->maxdev = 0.0;
  s->run = false;
}

static SDL_Window *window;

SDL_AppResult SDL_AppInit(void **appstate,
                          __attribute__((unused)) int argc,
                          __attribute__((unused)) char **argv)
{
  // Initialize state needed in all functions.
  static Simulation s = {0};
  reset(&s);
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
  int h = 500;
  if (!SDL_CreateWindowAndRenderer("Cairo SDL3 IMGUI robit demo", w, h, 0,
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
  Simulation *s = appstate;
  const double GM = 1.0;
  const double dt = 0.25;
  // GUI definition starts here.
  gui_begin();
  // Close button
  if (gui_button(gui_frombl(10, 50), "Close")) {
    return SDL_APP_SUCCESS;
  }
  // Show cursor position to help with layout.
  static bool show_mouse;
  gui_checkbox(gui_frombl(100, 33), "show mouse:", &show_mouse);
  char buf[80] = {0};
  if (show_mouse) {
    // Show cursor position to help with layout.
    GUI_veci2 mouse = gui_get_mouse_pos();
    snprintf(buf, 79, "x = %d, y = %d", mouse.x, mouse.y);
    gui_label(gui_frombl(230, 29), buf);
  }
  // start and reset buttons
  gui_checkbox(gui_frombl(10, 160), "Run", &s->run);
  if (gui_button(gui_frombl(10, 120), "Reset")) {
    reset(s);
  }
  memset(buf, 0, 80);
  snprintf(buf, 79, "radius deviation: %4.2f%%", s->dev * 100.0);
  gui_label((GUI_vec2) {10, 10}, buf);
  memset(buf, 0, 80);
  snprintf(buf, 79, "max. radius deviation: %4.2f%%", s->maxdev * 100.0);
  gui_label((GUI_vec2) {10, 35}, buf);
  if (s->run) {
    // Calculations
    double l = len(s->pos);
    s->dev = fabs(l - 1.0);
    if (s->dev > s->maxdev) {
      s->maxdev = s->dev;
    }
    double l3 = pow(l, 3);
    // First accelleration
    s->acc.x = -GM * s->pos.x / l3;
    s->acc.y = -GM * s->pos.y / l3;
    // Then velocity
    s->vel.x += s->acc.x * dt;
    s->vel.y += s->acc.y * dt;
    // Finally, update position
    s->pos.x += s->vel.x * dt;
    s->pos.y += s->vel.y * dt;
  }
  // You can still draw here, between cairo_save and cairo_restore
  cairo_t *ctx = gui_get_context();
  cairo_save(ctx);
  cairo_translate(ctx, 350, 250);
  cairo_scale(ctx, 1.0, -1.0);
  // Draw the sun
  cairo_pattern_t *cp = cairo_pattern_create_radial(0.0, 0.0, 5.0, 0.0, 0.0, 40.0);
  cairo_pattern_add_color_stop_rgba(cp, 0.0, 1.0, 1.0, 0.0, 1.0);
  cairo_pattern_add_color_stop_rgba(cp, 1.0, 1.0, 1.0, 0.0, 0.0);
  cairo_arc(ctx, 0.0, 0.0, 40.0, 0, 2 * M_PI);
  cairo_set_source(ctx, cp);
  cairo_fill(ctx);
  cairo_pattern_destroy(cp);
  // Draw orbit of body
  cairo_set_source_rgba(ctx, 1.0, 0.0, 0.0, 0.5);
  cairo_arc(ctx, 0.0, 0.0, SCALE, 0, 2 * M_PI);
  cairo_stroke(ctx);
  // Draw current position of body
  cairo_set_source_rgb(ctx, 0.2, 0.2, 1.0);
  cairo_arc(ctx, s->pos.x * SCALE, s->pos.y * SCALE, 4.0, 0, 2 * M_PI);
  cairo_fill(ctx);
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
