// file: cube-demo.c
// vim:fileencoding=utf-8:ft=c:tabstop=2
// This is free and unencumbered software released into the public domain.
//
// Author: R.F. Smith <rsmith@xs4all.nl>
// SPDX-License-Identifier: Unlicense
// Created: 2026-05-15 12:45:27 +0200
// Last modified: 2026-05-15T12:51:13+0200

#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <cairo/cairo.h>

#include "cairo-imgui.h"

#include <assert.h>
#include <stdio.h>
#include <math.h>

typedef struct {
  double x, y, z;
} Vec3;

typedef struct {
  double rc11, rc12, rc13,
         rc21, rc22, rc23,
         rc31, rc32, rc33;
} Mat3;

typedef struct {
  int xdeg, ydeg, zdeg;
  double xrad, yrad, zrad;
  Mat3 xf;
  Vec3 vp[12];
  bool checked;
} State;

#define SZ 120.0
const Vec3 points[12] = {
  // Cube
  {-SZ, -SZ, -SZ},
  {SZ, -SZ, -SZ},
  {SZ, SZ, -SZ},
  {-SZ, SZ, -SZ},
  {-SZ, -SZ, SZ},
  {SZ, -SZ, SZ},
  {SZ, SZ, SZ},
  {-SZ, SZ, SZ},
  // Origin and axes end points.
  {0.0, 0.0, 0.0},
  {SZ, 0.0, 0.0},
  {0.0, SZ, 0.0},
  {0.0, 0.0, SZ}
};

void m3xform(Mat3 m, Vec3 *in, Vec3 *out, int count);

Mat3 extrinsic(double g, double b, double a);

void transform(State *s);

static SDL_Window *window;

SDL_AppResult SDL_AppInit(void **appstate,
                          __attribute__((unused)) int argc,
                          __attribute__((unused)) char **argv)
{
  // Initialize state needed in all functions.
  static State s = {0};
  s.xf = (Mat3) {1.0, 0.0, 0.0,  0.0, 1.0, 0.0,  0.0, 0.0, 1.0};
  s.xdeg = 19;
  s.ydeg = 23;
  s.xrad = s.xdeg * M_PI / 180.0;
  s.yrad = s.ydeg * M_PI / 180.0;
  transform(&s);
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
  gui_label((GUI_vec2) {10, 440}, "Extrinsic rotation");
  char buf[20] = {0};
  bool change = false;
  // X angle
  gui_label((GUI_vec2) {10, 470}, "X angle:");
  if (gui_hbar((GUI_vec2) {80, 470}, 360, &s->xdeg)) {
    s->xrad = s->xdeg * M_PI / 180.0;
    change = true;
  }
  snprintf(buf, 19, "%d degrees", s->xdeg);
  gui_label((GUI_vec2) {460, 470}, buf);
  // Y angle
  gui_label((GUI_vec2) {10, 500}, "Y angle:");
  if (gui_hbar((GUI_vec2) {80, 500}, 360, &s->ydeg)) {
    s->yrad = s->ydeg  * M_PI / 180.0;
    change = true;
  }
  memset(buf, 0, 20);
  snprintf(buf, 19, "%d degrees", s->ydeg);
  gui_label((GUI_vec2) {460, 500}, buf);
  // Z-angle
  gui_label((GUI_vec2) {10, 530}, "Z angle:");
  if (gui_hbar((GUI_vec2) {80, 530}, 360, &s->zdeg)) {
    s->zrad = s->zdeg  * M_PI / 180.0;
    change = true;
  }
  memset(buf, 0, 20);
  snprintf(buf, 19, "%d degrees", s->zdeg);
  gui_label((GUI_vec2) {460, 530}, buf);
  if (change == true) {
    transform(s);
  }
  // You can still draw here, between cairo_save and cairo_restore
  cairo_t *ctx = gui_get_context();
  cairo_save(ctx);
  cairo_translate(ctx, 300, 250);
  // Screen transform; Y axis should point upward.
  cairo_scale(ctx, 1.0, -1.0);
  // Axes
  cairo_new_path(ctx);
  cairo_set_source_rgb(ctx, 1.0, 0.0, 0.0); // X is red
  cairo_move_to(ctx, s->vp[8].x, s->vp[8].y);
  cairo_line_to(ctx, s->vp[9].x, s->vp[9].y);
  cairo_stroke(ctx);
  cairo_new_path(ctx);
  cairo_set_source_rgb(ctx, 0.0, 1.0, 0.0); // Y is green
  cairo_move_to(ctx, s->vp[8].x, s->vp[8].y);
  cairo_line_to(ctx, s->vp[10].x, s->vp[10].y);
  cairo_stroke(ctx);
  cairo_new_path(ctx);
  cairo_set_source_rgb(ctx, 0.0, 0.0, 1.0); // Z is blue
  cairo_move_to(ctx, s->vp[8].x, s->vp[8].y);
  cairo_line_to(ctx, s->vp[11].x, s->vp[11].y);
  cairo_stroke(ctx);
  gui_use_fg();
  // Bottom edges
  cairo_new_path(ctx);
  cairo_move_to(ctx, s->vp[0].x, s->vp[0].y);
  cairo_line_to(ctx, s->vp[1].x, s->vp[1].y);
  cairo_line_to(ctx, s->vp[2].x, s->vp[2].y);
  cairo_line_to(ctx, s->vp[3].x, s->vp[3].y);
  cairo_close_path(ctx);
  cairo_stroke(ctx);
  // Top edges
  cairo_new_path(ctx);
  cairo_move_to(ctx, s->vp[4].x, s->vp[4].y);
  cairo_line_to(ctx, s->vp[5].x, s->vp[5].y);
  cairo_line_to(ctx, s->vp[6].x, s->vp[6].y);
  cairo_line_to(ctx, s->vp[7].x, s->vp[7].y);
  cairo_close_path(ctx);
  // Connecting edges.
  cairo_stroke(ctx);
  cairo_new_path(ctx);
  cairo_move_to(ctx, s->vp[0].x, s->vp[0].y);
  cairo_line_to(ctx, s->vp[4].x, s->vp[4].y);
  cairo_stroke(ctx);
  cairo_new_path(ctx);
  cairo_move_to(ctx, s->vp[1].x, s->vp[1].y);
  cairo_line_to(ctx, s->vp[5].x, s->vp[5].y);
  cairo_stroke(ctx);
  cairo_new_path(ctx);
  cairo_move_to(ctx, s->vp[2].x, s->vp[2].y);
  cairo_line_to(ctx, s->vp[6].x, s->vp[6].y);
  cairo_stroke(ctx);
  cairo_new_path(ctx);
  cairo_move_to(ctx, s->vp[3].x, s->vp[3].y);
  cairo_line_to(ctx, s->vp[7].x, s->vp[7].y);
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

void m3xform(Mat3 m, Vec3 *in, Vec3 *out, int count)
{
  for (int j = 0; j < count; j++) {
    Vec3 tmp = {
      m.rc11 * in[j].x + m.rc12 * in[j].y + m.rc13 * in[j].z,
      m.rc21 * in[j].x + m.rc22 * in[j].y + m.rc23 * in[j].z,
      m.rc31 * in[j].x + m.rc32 * in[j].y + m.rc33 * in[j].z,
    };
    out[j].x = tmp.x;
    out[j].y = tmp.y;
    out[j].z = tmp.z;
  }
}

// Source:
// https://en.wikipedia.org/wiki/Rotation_matrix#General_3D_rotations
//
// Wikipedia gives extrinsic notation. But it looks like α and γ
// are swapped in the formulas
// So Rex = Rz(γ)·Ry(β)·Rx(α)
Mat3 extrinsic(double Rx, double Ry, double Rz)
{
  double cg = cos(Rz), sg = sin(Rz);
  double cb = cos(Ry), sb = sin(Ry);
  double ca = cos(Rx), sa = sin(Rx);
  return (Mat3) {
    cb*cg, sa*sb*cg - ca*sg, ca*sb*cg + sa*sg,
    cb*sg, sa*sb*sg + ca*cg, ca*sb*sg - sa*cg,
    -sb, sa*cb, ca*cb
  };
}

// This one is correct!
Mat3 intrinsic(double Rx, double Ry, double Rz)
{
  double cg = cos(Rx), sg = sin(Rx);
  double cb = cos(Ry), sb = sin(Ry);
  double ca = cos(Rz), sa = sin(Rz);
  return (Mat3) {
    ca*cb, ca*sb*sg - sa*cg, ca*sb*cg + sa*sg,
    sa*cb, sa*sb*sg + ca*cg, sa*sb*cg - ca*sg,
    -sb, cb*sg, cb*cg
  };
}

void transform(State *s)
{
  s->xf = extrinsic(s->xrad, s->yrad, s->zrad);
  m3xform(s->xf, (Vec3 *)&points, s->vp, 12);
}
