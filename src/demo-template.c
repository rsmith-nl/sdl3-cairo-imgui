// file: demo-template.c
// vim:fileencoding=utf-8:ft=c:tabstop=2
// This is free and unencumbered software released into the public domain.
//
// Author: R.F. Smith <rsmith@xs4all.nl>
// SPDX-License-Identifier: Unlicense
// Created: 2026-05-15 11:26:22 +0200
// Last modified: 2026-05-15T11:33:09+0200

#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <cairo/cairo.h>

#include "cairo-imgui.h"

#include <assert.h>
#include <stdio.h>

typedef struct {
  bool checked;
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
  int w = 400;
  int h = 320;
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
  // You can still draw here, between cairo_save and cairo_restore
  cairo_t *ctx = gui_get_context();
  cairo_save(ctx);
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
