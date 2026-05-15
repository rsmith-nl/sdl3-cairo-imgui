// file: cairo-imgui-demo.c
// vim:fileencoding=utf-8:ft=c:tabstop=2
// This is free and unencumbered software released into the public domain.
//
// Author: R.F. Smith <rsmith@xs4all.nl>
// SPDX-License-Identifier: Unlicense
// Created: 2025-08-18 14:53:46 +0200
// Last modified: 2026-05-15T01:38:30+0200

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

SDL_AppResult SDL_AppInit(void **appstate, int argc, char **argv)
{
  (void)argc;
  (void)argv;
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
  if (!SDL_CreateWindowAndRenderer("Cairo SDL3 IMGUI demo", w, h, 0,
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
  // Buttom + label to show counter...
  static int count = 0;
  static char bbuf[40] = "Not pressed";
  if (gui_button((GUI_vec2) {10, 10}, "Test")) {
    snprintf(bbuf, 39, "Pressed %d times", ++count);
  }
  gui_label((GUI_vec2) {75, 17}, bbuf);
  if (gui_button(gui_frombl(10, 50), "Close")) {
    return SDL_APP_SUCCESS;
  }
  static char *slabel = "Not checked";
  if (gui_checkbox((GUI_vec2) {10, 50}, "Checkbox", &s->checked)) {
    if (s->checked) {
      slabel = "Checked";
    } else {
      slabel = "Not checked";
    }
  }
  gui_label((GUI_vec2) {120, 55}, slabel);
  static char *btns[2] = {"light", "dark"};
  static int radio = 1;
  gui_label((GUI_vec2) {10, 80}, "Theme");
  if (gui_radiobuttons((GUI_vec2) {10, 92}, 2, btns, &radio)) {
    if (radio == 0) {
      gui_theme_solarized_light();
      // puts("switching to light theme.");
    } else if (radio == 1) {
      gui_theme_solarized_dark();
      // puts("switching to dark theme.");
    }
  }
  // Color sliders and sample.
  gui_label((GUI_vec2) {10, 139}, "Red");
  gui_label((GUI_vec2) {10, 169}, "Green");
  gui_label((GUI_vec2) {10, 199}, "Blue");
  static int red = 0, green = 0, blue = 0;
  static GUI_rgb samplecolor = {0};
  static char bred[10] = {0}, bgreen[10] = {0}, bblue[10] = {0};
  if (gui_hbar((GUI_vec2) {60, 135}, 255, &red)) {
    samplecolor.r = (double)red / 255.0;
  }
  if (gui_hbar((GUI_vec2) {60, 165}, 255, &green)) {
    samplecolor.g = (double)green / 255.0;
  }
  if (gui_hbar((GUI_vec2) {60, 195}, 255, &blue)) {
    samplecolor.b = (double)blue / 255.0;
  }
  snprintf(bred, 9, "%d", red);
  snprintf(bgreen, 9, "%d", green);
  snprintf(bblue, 9, "%d", blue);
  gui_label((GUI_vec2) {355, 124}, bred);
  gui_label((GUI_vec2) {355, 154}, bgreen);
  gui_label((GUI_vec2) {355, 184}, bblue);
  gui_colorsample((GUI_vec2) {250.0, 10.0}, 100.0, 100.0, &samplecolor);
  // Spinner
  static int32_t ispinner = 17;
  gui_ispinner((GUI_vec2) {65.0, 225.0}, 0, 255, &ispinner);
  // Edit box
  static GUI_editstate es = {0};
  gui_editbox((GUI_vec2) {150.0, 225.0}, 100.0, &es);
  // Show cursor position to help with layout.
  static bool show_mouse;
  gui_checkbox(gui_frombl(80, 40), "show mouse:", &show_mouse);
  if (show_mouse) {
    // Show cursor position to help with layout.
    char buf[80] = {0};
    GUI_veci2 mouse = gui_get_mouse_pos();
    snprintf(buf, 79, "x = %d, y = %d", mouse.x, mouse.y);
    gui_label(gui_frombl(210, 36), buf);
  }
  // You can still draw here...
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
