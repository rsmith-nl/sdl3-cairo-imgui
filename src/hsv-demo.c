// file: hsv-demo.c
// vim:fileencoding=utf-8:ft=c:tabstop=2
// This is free and unencumbered software released into the public domain.
//
// Author: R.F. Smith <rsmith@xs4all.nl>
// SPDX-License-Identifier: Unlicense
// Created: 2026-05-15 12:53:25 +0200
// Last modified: 2026-05-15T13:06:32+0200

#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <cairo/cairo.h>

#include "cairo-imgui.h"

#include <assert.h>
#include <stdio.h>
#include <math.h>

typedef struct {
  cairo_surface_t *image;
  bool checked;
} State;

// Color conversion function.
GUI_rgb HSVtoRGB(double hue, double saturation, double value);

static SDL_Window *window;

SDL_AppResult SDL_AppInit(void **appstate,
                          __attribute__((unused)) int argc,
                          __attribute__((unused)) char **argv)
{
  // Initialize state needed in all functions.
  static State s = {0};
  // Create and fill color bar.
  s.image = cairo_image_surface_create(CAIRO_FORMAT_RGB24, 360, 20);
  cairo_t *ic = cairo_create(s.image);
  for (int j = 0; j < 360; j++) {
    GUI_rgb lc = HSVtoRGB(j, 1.0, 1.0);
    cairo_new_path(ic);
    cairo_set_source_rgb(ic, lc.r, lc.g, lc.b);
    cairo_move_to(ic, j, 0);
    cairo_line_to(ic, j, 20);
    cairo_stroke(ic);
  }
  cairo_destroy(ic);
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
  int w = 420;
  int h = 300;
  if (!SDL_CreateWindowAndRenderer("Cairo SDL3 IMGUI HSV demo", w, h, 0,
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
  char buf[256] = {0};
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
  static int H, Si = 100, Vi = 100;
  // Slider bars for H, S and V
  gui_label((GUI_vec2) {10, 154}, "H:");
  gui_hbar((GUI_vec2) {30, 150}, 360, &H);
  gui_label((GUI_vec2) {10, 184}, "S:");
  gui_hbar((GUI_vec2) {30, 180}, 100, &Si);
  gui_label((GUI_vec2) {10, 214}, "V:");
  gui_hbar((GUI_vec2) {30, 210}, 100, &Vi);
  // Calculate values
  double S = Si / 100.0, V = Vi / 100.0;
  static GUI_rgb clr;
  static int R, G, B;
  clr = HSVtoRGB(H, S, V);
  R = (int)(clr.r * 255);
  G = (int)(clr.g * 255);
  B = (int)(clr.b * 255);
  // Color sample
  gui_colorsample((GUI_vec2) {250, 10}, 150, 100, &clr);
  // Color labels
  memset(buf, 0, 256);
  snprintf(buf, 255, "H = %03d°, S = %4.2f, V = %4.2f", H, S, V);
  gui_label((GUI_vec2) {10, 20}, buf);
  memset(buf, 0, 256);
  snprintf(buf, 255, "R = %03d, G = %03d, B = %03d", R, G, B);
  gui_label((GUI_vec2) {10, 40}, buf);
  snprintf(buf, 255, "hex RGB = 0x%02X%02X%02X", R, G, B);
  gui_label((GUI_vec2) {10, 60}, buf);
  // You can still draw here, between cairo_save and cairo_restore
  cairo_t *ctx = gui_get_context();
  cairo_save(ctx);
  cairo_set_source_surface(ctx, s->image, 35, 120);
  cairo_new_path(ctx);
  cairo_move_to(ctx, 35, 120);
  cairo_line_to(ctx, 395, 120);
  cairo_line_to(ctx, 395, 150);
  cairo_line_to(ctx, 35, 150);
  cairo_close_path(ctx);
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

GUI_rgb HSVtoRGB(double hue, double saturation, double value)
{
  GUI_rgb rv = {0};
  // Red channel
  double k = fmod((5.0 + hue / 60.0), 6);
  double t = 4.0 - k;
  k = (t < k) ? t : k;
  k = (k < 1) ? k : 1;
  k = (k > 0) ? k : 0;
  rv.r = value - value * saturation * k;
  // Green channel
  k = fmod((3.0 + hue / 60.0f), 6);
  t = 4.0 - k;
  k = (t < k) ? t : k;
  k = (k < 1) ? k : 1;
  k = (k > 0) ? k : 0;
  rv.g = value - value * saturation * k;
  // Blue channel
  k = fmod((1.0 + hue / 60.0), 6);
  t = 4.0 - k;
  k = (t < k) ? t : k;
  k = (k < 1) ? k : 1;
  k = (k > 0) ? k : 0;
  rv.b = value - value * saturation * k;
  return rv;
}
