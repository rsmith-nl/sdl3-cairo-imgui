// file: cairo-imgui-demo.c
// vim:fileencoding=utf-8:ft=c:tabstop=2
// This is free and unencumbered software released into the public domain.
//
// Author: R.F. Smith <rsmith@xs4all.nl>
// SPDX-License-Identifier: Unlicense
// Created: 2025-08-18 14:53:46 +0200
// Last modified: 2025-08-27T11:38:07+0200

#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <cairo/cairo.h>

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
  gui_theme_dark(&ctx);
  // Make context available to other callbacks.
  *appstate = &s;
  if (!SDL_Init(SDL_INIT_VIDEO)) {
    SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
    return SDL_APP_FAILURE;
  }
  // The SDL_AppIterate callback should run ≈10× per second.
  SDL_SetHint(SDL_HINT_MAIN_CALLBACK_RATE, "10");
  // Create window and renderer.
  int w = 400;
  int h = 300;
  if (!SDL_CreateWindowAndRenderer("Cairo IMGUI demo", w, h, 0,
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
  // Buttom + label to show counter...
  static int count = 0;
  static char bbuf[40] = "Not pressed";
  if (gui_button(s->ctx, 10, 10, "Test")) {
      snprintf(bbuf, 39, "Pressed %d times", ++count);
  }
  gui_label(s->ctx, 60, 18, bbuf);
  if (gui_button(s->ctx, 10, 260, "Close")) {
      return SDL_APP_SUCCESS;
  }
  static char *slabel = "Not checked";
  if (gui_checkbox(s->ctx, 10, 50, "Checkbox", &s->checked)) {
    if (s->checked) {
      slabel = "Checked";
    } else {
      slabel = "Not checked";
    }
  }
  gui_label(s->ctx, 80, 51.5, slabel);
  static const char *btns[2] = {"light", "dark"};
  static int radio = 1;
  gui_label(s->ctx, 10, 70, "Theme");
  if (gui_radiobuttons(s->ctx, 10, 80, 2, btns, &radio)) {
    if (radio == 0) {
      gui_theme_light(s->ctx);
      // puts("switching to light theme.");
    } else if (radio == 1) {
      gui_theme_dark(s->ctx);
      // puts("switching to dark theme.");
    }
  }
  gui_label(s->ctx, 10, 124, "Red");
  gui_label(s->ctx, 10, 154, "Green");
  gui_label(s->ctx, 10, 184, "Blue");
  static int red = 0, green = 0, blue = 0;
  static GUI_rgb samplecolor = {0};
  static char bred[10] = {0}, bgreen[10] = {0}, bblue[10] = {0};
  if (gui_slider(s->ctx, 50, 120, &red)) {
    samplecolor.r = (double)red/255.0;
  }
  if (gui_slider(s->ctx, 50, 150, &green)) {
    samplecolor.g = (double)green/255.0;
  }
  if (gui_slider(s->ctx, 50, 180, &blue)) {
    samplecolor.b = (double)blue/255.0;
  }
  snprintf(bred, 9, "%d", red);
  snprintf(bgreen, 9, "%d", green);
  snprintf(bblue, 9, "%d", blue);
  gui_label(s->ctx, 346, 124, bred);
  gui_label(s->ctx, 346, 154, bgreen);
  gui_label(s->ctx, 346, 184, bblue);
  gui_colorsample(s->ctx, 200.0, 10.0, 100.0, 100.0, &samplecolor);
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
