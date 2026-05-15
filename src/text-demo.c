// file: text-demo.c
// vim:fileencoding=utf-8:ft=c:tabstop=2
// This is free and unencumbered software released into the public domain.
//
// Author: R.F. Smith <rsmith@xs4all.nl>
// SPDX-License-Identifier: Unlicense
// Created: 2026-05-15 14:07:04 +0200
// Last modified: 2026-05-15T14:12:24+0200

#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <cairo/cairo.h>

#include "cairo-imgui.h"

#include <assert.h>
#include <stdio.h>
#include <math.h>

static SDL_Window *window;

SDL_AppResult SDL_AppInit(__attribute__((unused)) void **appstate,
                          __attribute__((unused)) int argc,
                          __attribute__((unused)) char **argv)
{
  // Set a theme for the GUI.
  gui_theme_solarized_dark();
  // Make context available to other callbacks.
  if (!SDL_Init(SDL_INIT_VIDEO)) {
    SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
    return SDL_APP_FAILURE;
  }
  // The SDL_AppIterate callback should run ≈30× per second.
  SDL_SetHint(SDL_HINT_MAIN_CALLBACK_RATE, "30");
  // Create window and renderer.
  int w = 600;
  int h = 300;
  if (!SDL_CreateWindowAndRenderer("Cairo SDL3 IMGUI demo template", w, h, 0,
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

SDL_AppResult SDL_AppIterate(__attribute__((unused)) void *appstate)
{
  // GUI definition starts here.
  gui_begin();
  // Close button
  if (gui_button(gui_frombl(10, 40), "Close")) {
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
  // Slider for font size.
  static int fontsize = 70;
  int size = fontsize - 20;
  gui_label((GUI_vec2) {10, 210}, "Font size");
  if (gui_hbar((GUI_vec2) {10, 230}, 100, &size)) {
    fontsize = size + 20;
  }
  memset(buf, 0, 79);
  snprintf(buf, 79, "%d", fontsize);
  gui_label((GUI_vec2) {130, 233}, buf);
  // You can still draw here, between cairo_save and cairo_restore
  cairo_t *ctx = gui_get_context();
  cairo_save(ctx);
  char *text = "MgQjPk";
  double x = 80, y = 160;
  cairo_select_font_face(ctx, "Sans",
                         CAIRO_FONT_SLANT_NORMAL,
                         CAIRO_FONT_WEIGHT_NORMAL);
  cairo_set_font_size(ctx, fontsize);
  cairo_text_extents_t extents;
  cairo_font_extents_t fext;
  cairo_text_extents(ctx, text, &extents);
  cairo_font_extents(ctx,  &fext);
  cairo_move_to(ctx, x, y);
  cairo_show_text(ctx, text);
  /* Draw helping lines */
  // Red circle (filled)
  //cairo_arc (ctx, x, y, 10.0, 0, 2 * M_PI);
  //cairo_fill (ctx);
  // Red circle (patterned).
  cairo_pattern_t *cp = cairo_pattern_create_radial(x, y, 5, x, y, 10);
  cairo_pattern_add_color_stop_rgba(cp, 0.0, 1.0, 0.2, 0.2, 0.6);
  cairo_pattern_add_color_stop_rgba(cp, 1.0, 1.0, 0.2, 0.2, 0.1);
  cairo_arc(ctx, x, y, 10.0, 0, 2 * M_PI);
  cairo_set_source(ctx, cp);
  cairo_fill (ctx);
  cairo_pattern_destroy(cp);
// Lines
  cairo_set_source_rgba (ctx, 1, 0.2, 0.2, 0.6);
  cairo_set_line_width (ctx, 6.0);
  cairo_move_to (ctx, x, y);
  cairo_rel_line_to(ctx, 0, -extents.height);
  cairo_rel_line_to(ctx, extents.width, 0);
  cairo_rel_line_to(ctx, extents.x_bearing, -extents.y_bearing);
  cairo_stroke (ctx);
  // baseline
  cairo_set_source_rgba (ctx, 0.2, 1.0, 0.2, 0.6);
  cairo_set_font_size (ctx, 15);
  cairo_set_line_width (ctx, 3.0);
  cairo_move_to(ctx, x, y);
  cairo_rel_line_to(ctx, extents.width, 0);
  cairo_stroke(ctx);
  cairo_move_to(ctx, x + extents.width, y);
  cairo_show_text(ctx, "baseline");
  // ascent
  cairo_set_source_rgba (ctx, 0.2, 1.0, 0.2, 0.6);
  cairo_set_line_width (ctx, 2.0);
  cairo_move_to(ctx, x, y - fext.ascent);
  cairo_rel_line_to (ctx, extents.width, 0);
  cairo_stroke(ctx);
  cairo_move_to(ctx, x + extents.width, y - fext.ascent);
  cairo_show_text(ctx, "ascent");
  // descent
  cairo_set_source_rgba (ctx, 0.2, 1.0, 0.2, 0.6);
  cairo_set_line_width (ctx, 2.0);
  cairo_move_to(ctx, x, y + fext.descent);
  cairo_rel_line_to (ctx, extents.width, 0);
  cairo_stroke(ctx);
  cairo_move_to(ctx, x + extents.width, y + fext.descent);
  cairo_show_text(ctx, "descent");
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
