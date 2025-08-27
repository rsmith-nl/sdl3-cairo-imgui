// file: cairo-guitest.c
// vim:fileencoding=utf-8:ft=c:tabstop=2
// This is free and unencumbered software released into the public domain.
//
// Author: R.F. Smith <rsmith@xs4all.nl>
// SPDX-License-Identifier: Unlicense
// Created: 2025-08-18 14:53:46 +0200
// Last modified: 2025-08-26T23:32:53+0200

#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <cairo/cairo.h>

#define CAIRO_IMGUI_IMPLEMENTATION
#include "cairo-imgui.h"

#include <assert.h>
#include <stdio.h>

typedef struct {
  SDL_Window *window;
  SDL_Renderer *renderer;
  SDL_Texture *texture;
  GUI_context *ctx;
  bool checked;
} State;


SDL_AppResult SDL_AppInit(void **appstate, int argc, char **argv)
{
  (void)argc;
  (void)argv;
  // Initialize state needed in all functions.
  static State s = {0};
  // Create GUI context.
  static GUI_context ctx = {0};
  s.ctx = &ctx;
  // Set a theme for the GUI.
  gui_theme_light(&ctx);
  // Make context available to other callbacks.
  *appstate = &s;
  if (!SDL_Init(SDL_INIT_VIDEO)) {
    SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
    return SDL_APP_FAILURE;
  }
  // The SDL_AppIterate callback should run ≈5× per second.
  SDL_SetHint(SDL_HINT_MAIN_CALLBACK_RATE, "5");
  // Create window and renderer.
  int w = 200;
  int h = 200;
  if (!SDL_CreateWindowAndRenderer("Cairo IMGUI test", w, h, 0,
                                   &s.window, &s.renderer)) {
    SDL_Log("Couldn't create a window and renderer: %s", SDL_GetError());
    return SDL_APP_FAILURE;
  }
  // Render on vsync to prevent tearing
  SDL_SetRenderVSync(s.renderer, SDL_RENDERER_VSYNC_ADAPTIVE);
  // Create texture for cairo to render to.
  s.texture = SDL_CreateTexture(s.renderer, SDL_PIXELFORMAT_ARGB8888,
                                SDL_TEXTUREACCESS_STREAMING, w, h);
  return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void *appstate)
{
  (void)appstate;
  State *s = appstate;
  // GUI definition starts here.
  gui_begin(s->renderer, s->texture, s->ctx);
  if (gui_button(s->ctx, 10, 10, "Test")) {
    puts("buttom pressed");
  }
  if (gui_button(s->ctx, 10, 45, "Quit")) {
    return SDL_APP_SUCCESS;
  }
  if (gui_checkbox(s->ctx, 10, 90, "Checkbox", &s->checked)) {
    if (s->checked) {
      puts("checkbox set");
    } else {
      puts("checkbox unset");
    }
  }
  gui_label(s->ctx, 50, 10, "Theme");
  static const char *btns[2] = {"light", "dark"};
  static int radio = 0;
  if (gui_radiobuttons(s->ctx, 50, 30, 2, btns, &radio)) {
    if (radio == 0) {
      gui_theme_light(s->ctx);
      // puts("switching to light theme.");
    } else if (radio == 1) {
      gui_theme_dark(s->ctx);
      // puts("switching to dark theme.");
    }
  }
  // You can still draw to s->ctx here...
  // End of GUI definition
  gui_end(s->ctx);
  return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event)
{
  State *s = appstate;
  return gui_process_events(s->ctx, event);
}

void SDL_AppQuit(void *appstate, SDL_AppResult result)
{
  State *s = appstate;
  (void)result;
  // Clean up.
  SDL_DestroyTexture(s->texture);
  SDL_DestroyWindow(s->window);
  SDL_DestroyRenderer(s->renderer);
}
