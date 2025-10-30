// file: cairo-imgui-demo.c
// vim:fileencoding=utf-8:ft=c:tabstop=2
// This is free and unencumbered software released into the public domain.
//
// Author: R.F. Smith <rsmith@xs4all.nl>
// SPDX-License-Identifier: Unlicense
// Created: 2025-08-18 14:53:46 +0200
// Last modified: 2025-09-24T21:29:31+0200

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
  ctx.id = 1;
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
  gui_label(s->ctx, 75, 17, bbuf);
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
  gui_label(s->ctx, 100, 50, slabel);
  static const char *btns[2] = {"light", "dark"};
  static int radio = 1;
  gui_label(s->ctx, 10, 70, "Theme");
  if (gui_radiobuttons(s->ctx, 10, 82, 2, btns, &radio)) {
    if (radio == 0) {
      gui_theme_light(s->ctx);
      // puts("switching to light theme.");
    } else if (radio == 1) {
      gui_theme_dark(s->ctx);
      // puts("switching to dark theme.");
    }
  }
  // Color sliders and sample.
  gui_label(s->ctx, 10, 124, "Red");
  gui_label(s->ctx, 10, 154, "Green");
  gui_label(s->ctx, 10, 184, "Blue");
  static int red = 0, green = 0, blue = 0;
  static GUI_rgb samplecolor = {0};
  static char bred[10] = {0}, bgreen[10] = {0}, bblue[10] = {0};
  if (gui_slider(s->ctx, 60, 120, &red)) {
    samplecolor.r = (double)red/255.0;
  }
  if (gui_slider(s->ctx, 60, 150, &green)) {
    samplecolor.g = (double)green/255.0;
  }
  if (gui_slider(s->ctx, 60, 180, &blue)) {
    samplecolor.b = (double)blue/255.0;
  }
  snprintf(bred, 9, "%d", red);
  snprintf(bgreen, 9, "%d", green);
  snprintf(bblue, 9, "%d", blue);
  gui_label(s->ctx, 355, 124, bred);
  gui_label(s->ctx, 355, 154, bgreen);
  gui_label(s->ctx, 355, 184, bblue);
  gui_colorsample(s->ctx, 250.0, 10.0, 100.0, 100.0, &samplecolor);
  // Spinner
  static int32_t ispinner = 17;
  gui_ispinner(s->ctx, 65.0, 210.0, 0, 255, &ispinner);
  // Edit box
  static GUI_editstate es = {0};
  gui_editbox(s->ctx, 150.0, 210.0, 100.0, &es);
  // Show cursor position to help with layout.
  char buf[80] = {0};
  snprintf(buf, 79, "x = %d, y = %d", s->ctx->mouse_x, s->ctx->mouse_y);
  gui_label(s->ctx, 100, 270, buf);
  // You can still draw to s->ctx here...
  // Small animated indicator to verify frames are updating.
  {
    static int anim = 0;
    int rw = 0, rh = 0;
    SDL_GetCurrentRenderOutputSize(s->renderer, &rw, &rh);
    if (rw <= 0) rw = 400; // fallback
    // Move a tiny rectangle horizontally across the top.
    double x = 10.0 + (anim % (rw > 40 ? (rw - 40) : 10));
    double y = 8.0;
    cairo_new_path(s->ctx->ctx);
    cairo_set_source_rgb(s->ctx->ctx, s->ctx->acc.r, s->ctx->acc.g, s->ctx->acc.b);
    cairo_rectangle(s->ctx->ctx, x, y, 6.0, 6.0);
    cairo_fill(s->ctx->ctx);
    anim = (anim + 3) & 0x7fffffff; // keep it bounded
  }
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
