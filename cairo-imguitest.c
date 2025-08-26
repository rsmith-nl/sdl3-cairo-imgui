// file: cairo-guitest.c
// vim:fileencoding=utf-8:ft=c:tabstop=2
// This is free and unencumbered software released into the public domain.
//
// Author: R.F. Smith <rsmith@xs4all.nl>
// SPDX-License-Identifier: Unlicense
// Created: 2025-08-18 14:53:46 +0200
// Last modified: 2025-08-26T19:30:20+0200

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
  // Initialize context
  static State s = {0};
  static GUI_context ctx = {0};
  s.ctx = &ctx;
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
  char *btns[3] = {"one", "two", "three"};
  static int radio = 0;
  if(gui_radiobuttons(s->ctx, 50, 10, 3, btns, &radio)) {
    printf("radio selection changed: %d\n", radio);
  }
  gui_end(s->ctx);
  return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event)
{
  State *s = appstate;
  int w, h;
  switch (event->type) {
    case SDL_EVENT_WINDOW_RESIZED:
      // Resize the texture if the window size changes.
      SDL_DestroyTexture(s->texture);
      SDL_GetWindowSize(s->window, &w, &h);
      s->texture = SDL_CreateTexture(s->renderer, SDL_PIXELFORMAT_ARGB8888,
                                     SDL_TEXTUREACCESS_STREAMING, w, h);
      break;
    case SDL_EVENT_QUIT:
      return SDL_APP_SUCCESS;
      break;
    case SDL_EVENT_KEY_UP:
      if (event->key.key == 'q' || event->key.key == SDLK_ESCAPE) {
        return SDL_APP_SUCCESS;
      }
      break;
    case SDL_EVENT_MOUSE_MOTION:
      s->ctx->mouse_x = event->motion.x;
      s->ctx->mouse_y = event->motion.y;
      break;
    case SDL_EVENT_MOUSE_BUTTON_DOWN:
      s->ctx->button_pressed = true;
      s->ctx->button_released = false;
      break;
    case SDL_EVENT_MOUSE_BUTTON_UP:
      s->ctx->button_pressed = false;
      s->ctx->button_released = true;
      break;
    default:
      if (s->ctx->button_released) {
        s->ctx->button_released = false;
      }
      break;
  }
  return SDL_APP_CONTINUE;
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
