// file: cairo-imgui.c
// vim:fileencoding=utf-8:ft=c:tabstop=2
// This is free and unencumbered software released into the public domain.
//
// Author: R.F. Smith <rsmith@xs4all.nl>
// SPDX-License-Identifier: Unlicense
// Created: 2025-08-26 14:04:09 +0200
// Last modified: 2026-05-15T01:35:10+0200

#include "cairo-imgui.h"
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <cairo/cairo.h>
#include <SDL3/SDL.h>
#include <SDL3/SDL_events.h>
#include <SDL3/SDL_keycode.h>



SDL_Renderer *renderer;
SDL_Texture *texture;
static cairo_surface_t *surface;
static cairo_t *ctx;
static GUI_veci2 mouse;
static int w_width, w_height;
static int32_t id;
static int32_t keycode;
static int32_t counter;
static int32_t maxid;
static int16_t mod;
static bool button_pressed;
static bool button_released;
static bool redraw;
static GUI_rgb fg;
static GUI_rgb bg;
static GUI_rgb acc;
static cairo_font_extents_t fext;

void gui_begin(void)
{
  void *pixels;
  int pitch;
  SDL_GetCurrentRenderOutputSize(renderer, &w_width, &w_height);
  // Create cairo surface which maps to the SDL texture.
  SDL_LockTexture(texture, 0, &pixels, &pitch);
  surface = cairo_image_surface_create_for_data(
              (char unsigned*)pixels, CAIRO_FORMAT_ARGB32, w_width, w_height, pitch);
  // Create cairo context to draw on the surface.
  ctx = cairo_create(surface);
  // Set color to background, fill the surface)
  cairo_set_source_rgb(ctx, bg.r, bg.g, bg.b);
  cairo_paint(ctx);
  // Set font size
  cairo_set_font_size(ctx, 14.0);
  // Determine font extents.
  cairo_font_extents(ctx, &fext);
  // Determine the size of a capital M.
  cairo_text_extents_t ext;
  cairo_text_extents(ctx, "M", &ext);
  counter = 1;
}

void gui_end(void)
{
  assert(ctx);
  button_released = false;
  keycode = 0;
  mod = 0;
  // Clean up
  cairo_destroy(ctx);
  cairo_surface_destroy(surface);
  surface = 0;
  SDL_UnlockTexture(texture);
  SDL_RenderTexture(renderer, texture, 0, 0);
  SDL_RenderPresent(renderer);
  maxid = counter;
}

cairo_t *gui_get_context(void)
{
  return ctx;
}

// Use theme color
void gui_use_fg(void)
{
  cairo_set_source_rgb(ctx, fg.r, fg.g, fg.b);
}

void gui_use_bg(void)
{
  cairo_set_source_rgb(ctx, bg.r, bg.g, bg.b);
}

void gui_use_acc(void)
{
  cairo_set_source_rgb(ctx, acc.r, acc.g, acc.b);
}

// Retrieve input.
GUI_veci2 gui_get_mouse_pos(void)
{
  return mouse;
}

bool gui_button_pressed(void)
{
  return button_pressed & !button_released;
}

int32_t gui_get_keycode(void)
{
  return keycode;
}

void gui_theme_solarized_light(void)
{
  bg = (GUI_rgb) {
    0.992157, 0.964706, 0.890196
  }; // Base3 #fdf6e3
  fg = (GUI_rgb) {
    0.345098, 0.431373, 0.458824
  }; // Base01 #586e75
  acc = (GUI_rgb) {
    0.14902, 0.545098, 0.823529
  }; // Blue #268bd2
}

void gui_theme_solarized_dark(void)
{
  bg = (GUI_rgb) {
    0.027451, 0.211765, 0.258824
  }; // Base02 #073642
  fg = (GUI_rgb) {
    0.576471, 0.631373, 0.631373
  }; // Base1 #93a1a1
  acc = (GUI_rgb) {
    0.14902, 0.545098, 0.823529
  }; // Blue #268bd2
}

GUI_vec2 gui_frombl(double x, double y)
{
  GUI_vec2 rv = {x, w_height};
  rv.y -= y;
  return rv;
}

SDL_AppResult gui_process_events(SDL_Event *event)
{
  int w, h;
  switch (event->type) {
    case SDL_EVENT_WINDOW_RESIZED:
      // Resize the texture if the window size changes.
      SDL_DestroyTexture(texture);
      SDL_GetWindowSize(SDL_GetRenderWindow(renderer), &w, &h);
      texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
                                  SDL_TEXTUREACCESS_STREAMING, w, h);
      break;
    case SDL_EVENT_QUIT:
      return SDL_APP_SUCCESS;
      break;
    case SDL_EVENT_KEY_DOWN:
      if (event->key.key == 'q' || event->key.key == SDLK_ESCAPE) {
        return SDL_APP_SUCCESS;
      } else if (event->key.key == SDLK_TAB) {
        if (event->key.mod & (SDL_KMOD_LSHIFT | SDL_KMOD_RSHIFT)) {
          id--;
          if (id < 0) {
            id = maxid;
          }
        } else {
          id++;
          if (id > maxid) {
            id = 1;
          }
        }
      } else {
        keycode = event->key.key;
        mod = event->key.mod;
      }
      break;
    case SDL_EVENT_MOUSE_MOTION:
      mouse.x = event->motion.x;
      mouse.y = event->motion.y;
      break;
    case SDL_EVENT_MOUSE_BUTTON_DOWN:
      button_pressed = true;
      button_released = false;
      break;
    case SDL_EVENT_MOUSE_BUTTON_UP:
      button_pressed = false;
      button_released = true;
      break;
    default:
      if (button_released) {
        button_released = false;
      }
      break;
  }
  return SDL_APP_CONTINUE;
}


bool gui_button(GUI_vec2 left_top, char *label)
{
  // All interactive widgets should get an ID by increasing the counter.
  int32_t internal_id = counter++;
  double rv = false;
  double offset = 10.0;
  cairo_text_extents_t ext;
  cairo_text_extents(ctx, label, &ext);
  double width = 2 * offset + ext.width;
  double height = 2 * offset + fext.ascent + fext.descent;
  // Draw button outline.
  cairo_new_path(ctx);
  cairo_set_source_rgb(ctx, fg.r, fg.g, fg.b);
  cairo_rectangle(ctx, left_top.x, left_top.y, width, height);
  cairo_stroke(ctx);
  // draw/Fill inside if mouse is inside, or we have the highlight.
  if ((mouse.x >= left_top.x && (mouse.x - left_top.x) <= width &&
       mouse.y >= left_top.y && (mouse.y - left_top.y) <= height) || id == internal_id) {
    id = internal_id;
    cairo_new_path(ctx);
    cairo_set_source_rgb(ctx, acc.r, acc.g, acc.b);
    cairo_rectangle(ctx, left_top.x + 1, left_top.y + 1, width - 2, height - 2);
    if (button_pressed) {
      cairo_fill(ctx);
    } else {
      cairo_stroke(ctx);
    }
    if (button_released || keycode == SDLK_RETURN) {
      rv = true;
    }
  }
  // Draw the label
  cairo_new_path(ctx);
  cairo_set_source_rgb(ctx, fg.r, fg.g, fg.b);
  cairo_move_to(ctx, left_top.x + offset, left_top.y + offset + fext.ascent);
  cairo_show_text(ctx, label);
  cairo_fill(ctx);
  return rv;
}

void gui_label(GUI_vec2 left_top, char *label)
{
  // Labels don't interact, so they have no id.
  cairo_text_extents_t ext;
  cairo_text_extents(ctx, label, &ext);
  // Draw the label
  cairo_new_path(ctx);
  cairo_set_source_rgb(ctx, fg.r, fg.g, fg.b);
  cairo_move_to(ctx, left_top.x, left_top.y + ext.height);
  cairo_show_text(ctx, label);
  cairo_fill(ctx);
}

bool gui_checkbox(GUI_vec2 left_top, char *label, bool *state)
{
  int32_t internal_id = counter++;
  double rv = false;
  double offset = 5.0;
  double fheight = fext.ascent + fext.descent;
  double boxsize =  fheight > fext.max_x_advance ? fheight : fext.max_x_advance;
  boxsize *= 1.2;
  cairo_text_extents_t ext;
  cairo_text_extents(ctx, label, &ext);
  double width = 2 * offset + ext.width + boxsize;
  double height = 2 * offset + ext.height > boxsize ? ext.height : boxsize;
  // Draw checkbox outline.
  cairo_new_path(ctx);
  cairo_set_source_rgb(ctx, fg.r, fg.g, fg.b);
  cairo_rectangle(ctx, left_top.x, left_top.y, boxsize, boxsize);
  cairo_stroke(ctx);
  // draw/Fill inside if mouse is inside, or we have the highlight.
  if ((mouse.x >= left_top.x && (mouse.x - left_top.x) <= width &&
       mouse.y >= left_top.y && (mouse.y - left_top.y) <= height) || id == internal_id) {
    id = internal_id;
    cairo_new_path(ctx);
    cairo_set_source_rgb(ctx, acc.r, acc.g, acc.b);
    cairo_rectangle(ctx, left_top.x + 1, left_top.y + 1, boxsize - 2, boxsize - 2);
    if (button_pressed) {
      cairo_fill(ctx);
    } else {
      cairo_stroke(ctx);
    }
    if (button_released || keycode == SDLK_RETURN) {
      rv = true;
      *state = !*state;
    }
  }
  // Draw selected mark if needed.
  if (*state) {
    cairo_new_path(ctx);
    cairo_set_source_rgb(ctx, fg.r, fg.g, fg.b);
    cairo_move_to(ctx, left_top.x, left_top.y);
    cairo_rel_line_to(ctx, boxsize, boxsize);
    cairo_rel_move_to(ctx, 0, -boxsize);
    cairo_rel_line_to(ctx, -boxsize, boxsize);
    cairo_stroke(ctx);
  }
  // Draw the label
  cairo_new_path(ctx);
  cairo_set_source_rgb(ctx, fg.r, fg.g, fg.b);
  cairo_move_to(ctx, left_top.x + boxsize + offset, left_top.y + boxsize / 2 + ext.height / 2);
  cairo_show_text(ctx, label);
  cairo_fill(ctx);
  return rv;
}

bool gui_radiobuttons(GUI_vec2 left_top, int nlabels,
                      char *labels[nlabels], int *state)
{
  assert(labels);
  assert(nlabels > 0);
  int32_t internal_id = counter++;
  double rv = false;
  double offset = 5.0;
  double fheight = fext.ascent + fext.descent;
  double boxsize =  fheight > fext.max_x_advance ? fheight : fext.max_x_advance;
  double width, height;
  double heights[nlabels];
  double exty[nlabels];
  cairo_text_extents_t ext = {0};
  cairo_text_extents(ctx, labels[0], &ext);
  width = ext.width;
  height = ext.height;
  heights[0] = ext.height > boxsize ? ext.height : boxsize;
  exty[0] = ext.height;
  for (int k = 1; k < nlabels; k++) {
    cairo_text_extents(ctx, labels[k], &ext);
    heights[k] = ext.height > boxsize ? ext.height : boxsize;
    exty[k] = ext.height;
    if (width < ext.width) {
      width = ext.width;
    }
    height += heights[k];
  }
  width += 2 * offset + boxsize;
  height += 2 * offset;
  // Draw the buttons.
  int cury = left_top.y + boxsize / 2;
  int curx = left_top.x + boxsize / 2;
  // Draw the buttons and the selected one
  cairo_set_source_rgb(ctx, fg.r, fg.g, fg.b);
  for (int k = 0; k < nlabels; k++) {
    cairo_new_path(ctx);
    cairo_arc(ctx, curx, cury, boxsize / 2 - 2, 0.0, 2 * M_PI);
    cairo_stroke(ctx);
    if (*state == k) {
      cairo_new_path(ctx);
      cairo_arc(ctx, curx, cury, boxsize / 2 - 4, 0.0, 2 * M_PI);
      cairo_fill(ctx);
    }
    cury += heights[k];
  }
  // Draw the labels
  cury = left_top.y + offset;
  curx = left_top.x + boxsize + offset;
  cairo_new_path(ctx);
  cairo_set_source_rgb(ctx, fg.r, fg.g, fg.b);
  for (int k = 0; k < nlabels; k++) {
    cairo_move_to(ctx, curx, cury + exty[k] / 2);
    cairo_show_text(ctx, labels[k]);
    cury += heights[k];
  }
  cairo_fill(ctx);
  // draw/Fill inside if mouse is inside, or we have the highlight.
  if ((mouse.x >= left_top.x && (mouse.x - left_top.x) <= width &&
       mouse.y >= left_top.y && (mouse.y - left_top.y) <= height) || id == internal_id) {
    id = internal_id;
    cairo_new_path(ctx);
    cairo_set_source_rgb(ctx, acc.r, acc.g, acc.b);
    cury = left_top.y + boxsize / 2;
    curx = left_top.x + boxsize / 2;
    for (int k = 0; k < nlabels; k++) {
      if ((fabs((double)mouse.y - cury) < exty[k] / 2)) {
        // This is the label!
        cairo_new_path(ctx);
        cairo_arc(ctx, curx, cury, boxsize / 2 - 3, 0.0, 2 * M_PI);
        if (button_pressed) {
          cairo_fill(ctx);
        } else {
          cairo_stroke(ctx);
        }
        if (button_released || keycode == SDLK_RETURN) {
          rv = true;
          *state = k;
          redraw = true; // force redraw.
        } else if (keycode == SDLK_UP) {
          *state = --k;
          if (*state < 0) {
            *state = nlabels - 1;
          }
          redraw = true; // force redraw.
        } else if (keycode == SDLK_DOWN) {
          *state = ++k;
          if (*state == nlabels) {
            *state = 0;
          }
          redraw = true; // force redraw.
        }
        break;
      };
      cury += heights[k];
    }
  }
  return rv;
}

void gui_colorsample(GUI_vec2 left_top,
                     double w, double h, GUI_rgb *state)
{
  assert(state);
  cairo_new_path(ctx);
  cairo_set_source_rgb(ctx, state->r, state->g, state->b);
  cairo_rectangle(ctx, left_top.x, left_top.y, w, h);
  cairo_fill(ctx);
}

bool gui_hbar(GUI_vec2 left_top, int w, int *state)
{
  assert(state);
  int32_t internal_id = counter++;
  bool changed = false;
  const double ysize = 10.0;
  const double offset = 4.0;
  const double width = (double)w + 2 * offset;
  const double height = ysize + 2 * offset;
  // Draw outside rectangle
  cairo_new_path(ctx);
  cairo_set_source_rgb(ctx, fg.r, fg.g, fg.b);
  cairo_rectangle(ctx, left_top.x, left_top.y, width, height);
  cairo_stroke(ctx);
  // draw/Fill inside if mouse is inside, or we have the highlight.
  if ((mouse.x >= left_top.x && (mouse.x - left_top.x) <= width &&
       mouse.y >= left_top.y && (mouse.y - left_top.y) <= height) || id == internal_id) {
    id = internal_id;
    // draw inside if mouse is inside.
    cairo_new_path(ctx);
    cairo_set_source_rgb(ctx, acc.r, acc.g, acc.b);
    cairo_rectangle(ctx, left_top.x + 2, left_top.y + 2, width - 4, height - 4);
    cairo_stroke(ctx);
    // Update state if mouse is inside and button is pressed
    if (button_pressed || keycode == SDLK_RETURN) {
      int newstate = round(mouse.x - left_top.x - offset);
      if (newstate != *state) {
        *state = newstate;
        changed = true;
      }
    }
    if (keycode == SDLK_LEFT || keycode == SDLK_DOWN) {
      (*state)--;
      changed = true;
    } else if (keycode == SDLK_RIGHT || keycode == SDLK_UP) {
      (*state)++;
      changed = true;
    } else if (keycode == SDLK_HOME) {
      *state = 0;
      changed = true;
    }  else if (keycode == SDLK_END) {
      *state = w;
      changed = true;
    } else if (keycode == SDLK_PAGEUP) {
      (*state) += 10;
      changed = true;
    } else if (keycode == SDLK_PAGEDOWN) {
      (*state) -= 10;
      changed = true;
    }
  }
  // Clamp state within allowed range.
  if (*state < 0) {
    *state = 0;
  } else if (*state > w) {
    *state = w;
  }
  // Draw slider
  double sliderpos = (double) * state;
  cairo_new_path(ctx);
  cairo_set_source_rgb(ctx, fg.r, fg.g, fg.b);
  cairo_rectangle(ctx, left_top.x + offset, left_top.y + offset, sliderpos, ysize);
  cairo_fill(ctx);
  return changed;
}

bool gui_ispinner(GUI_vec2 left_top,
                  int32_t min, int32_t max, int32_t*state)
{
  assert(state);
  assert(max > min);
  int32_t internal_id = counter++;
  bool rv = false;
  // Determine the amount of characters needed
  cairo_text_extents_t zero;
  cairo_text_extents(ctx, "0", &zero);
  double maxw = ceil(log10(fabs((double)max))) * zero.width;
  const double offset = 6.0;
  const double boxsize = 12.0;
  double width = maxw + 2 * offset + 2 * boxsize;
  double height = fext.ascent + fext.descent + 2 * offset;
  // Draw the outline.
  cairo_new_path(ctx);
  cairo_set_source_rgb(ctx, fg.r, fg.g, fg.b);
  cairo_rectangle(ctx, left_top.x, left_top.y, width, height);
  cairo_stroke(ctx);
  // Draw the spinner buttons.
  cairo_new_path(ctx);
  cairo_set_source_rgb(ctx, fg.r, fg.g, fg.b);
  cairo_move_to(ctx, left_top.x + offset + maxw, left_top.y + offset + boxsize);
  cairo_rel_line_to(ctx, boxsize, 0);
  cairo_rel_line_to(ctx, -boxsize / 2, -boxsize);
  cairo_rel_line_to(ctx, -boxsize / 2, boxsize);
  cairo_close_path(ctx);
  cairo_fill(ctx);
  cairo_new_path(ctx);
  cairo_set_source_rgb(ctx, fg.r, fg.g, fg.b);
  cairo_move_to(ctx, left_top.x + offset + maxw + boxsize, left_top.y + offset);
  cairo_rel_line_to(ctx, boxsize, 0);
  cairo_rel_line_to(ctx, -boxsize / 2, boxsize);
  cairo_rel_line_to(ctx, -boxsize / 2, -boxsize);
  cairo_close_path(ctx);
  cairo_fill(ctx);
  if ((mouse.x >= left_top.x && (mouse.x - left_top.x) <= width &&
       mouse.y >= left_top.y && (mouse.y - left_top.y) <= height) || id == internal_id) {
    id = internal_id;
    // Draw inside accent if mouse is inside.
    cairo_new_path(ctx);
    cairo_set_source_rgb(ctx, acc.r, acc.g, acc.b);
    cairo_rectangle(ctx, left_top.x + 2, left_top.y + 2, width - 4, height - 4);
    cairo_stroke(ctx);
    if (button_pressed) {
      double xdist =  mouse.x - left_top.x - offset - maxw;
      if (xdist < boxsize) {
        (*state)++;
        rv = true;
      } else if (xdist > boxsize) {
        (*state)--;
        rv = true;
      }
    }
    // Update the value when up or down arrows are used.
    switch (keycode) {
      case SDLK_UP:
        (*state)++;
        rv = true;
        break;
      case SDLK_DOWN:
        (*state)--;
        rv = true;
        break;
      case SDLK_PAGEUP:
        (*state) += 10;
        rv = true;
        break;
      case SDLK_PAGEDOWN:
        (*state) -= 10;
        rv = true;
        break;
      case SDLK_HOME:
        *state = min;
        rv = true;
        break;
      case SDLK_END:
        *state = max;
        rv = true;
        break;
      default:
        break;
    }
  }
  // Clamp the state between min and max.
  if (*state > max) {
    *state = max;
  } else if (*state < min) {
    *state = min;
  }
  // Draw the number
  char buf[20];
  snprintf(buf, 19, "%d", *state);
  cairo_text_extents_t ext;
  cairo_text_extents(ctx, buf, &ext);
  cairo_new_path(ctx);
  cairo_set_source_rgb(ctx, fg.r, fg.g, fg.b);
  cairo_move_to(ctx, left_top.x + offset, left_top.y + offset + ext.height);
  cairo_show_text(ctx, buf);
  return rv;
}

static void recalc_cumwidth(GUI_editstate *s)
{
  memset(s->cumwidth, 0, EBUF_SIZE + 1);
  for (int j = 1; j <= s->used; j++) {
    char c[2] = {0};
    c[0] = s->data[j - 1];
    cairo_text_extents_t ext;
    cairo_text_extents(ctx, c, &ext);
    s->cumwidth[j] = ext.x_advance + s->cumwidth[j - 1];
  }
}

bool gui_editbox(GUI_vec2 left_top, double w, GUI_editstate *state)
{
  assert(state);
  int32_t internal_id = counter++;
  const double offset = 6.0;
  double height = fext.ascent + fext.descent + 2 * offset;
  bool rv = false;
  double net_width = w - 2 * offset;
  // Fill cumwidth
  recalc_cumwidth(state);
  // ---- Paint the editbox ----
  // Clear the background
  gui_use_bg();
  cairo_rectangle(ctx, left_top.x, left_top.y, w, height);
  cairo_fill(ctx);
  // Paint the outline
  gui_use_fg();
  cairo_rectangle(ctx, left_top.x, left_top.y, w, height);
  cairo_stroke(ctx);
  // Process keys if we have focus.
  if ((mouse.x >= left_top.x && (mouse.x - left_top.x) <= w &&
       mouse.y >= left_top.y && (mouse.y - left_top.y) <= height) || id == internal_id) {
    id = internal_id;
    // draw inside if mouse is inside.
    cairo_new_path(ctx);
    cairo_set_source_rgb(ctx, acc.r, acc.g, acc.b);
    cairo_rectangle(ctx, left_top.x + 2, left_top.y + 2, w - 4, height - 4);
    cairo_stroke(ctx);
    // Process keystrokes if we have focus
    switch (keycode) { // handle movement keys
      case SDLK_LEFT:
        if (state->cursorpos > 0) {
          state->cursorpos--;
          state->pixpos = state->cumwidth[state->cursorpos];
        }
        break;
      case SDLK_RIGHT:
        if (state->cursorpos < state->used) {
          state->cursorpos++;
          state->pixpos = state->cumwidth[state->cursorpos];
        }
        break;
      case SDLK_HOME:
        state->cursorpos = 0;
        state->pixpos = 0;
        break;
      case SDLK_END:
        state->cursorpos = state->used;
        cairo_text_extents_t ext;
        cairo_text_extents(ctx, state->data, &ext);
        state->pixpos = ext.x_advance;
        break;
      case SDLK_BACKSPACE:
        if (state->cursorpos == 0) {
          break;
        }
        state->cursorpos--;
        state->pixpos = state->cumwidth[state->cursorpos];
      // NO break!
      case SDLK_DELETE:
        if (state->cursorpos <= state->used && state->used > 0) {
          for (int j = state->cursorpos; j < state->used; j++) {
            state->data[j] = state->data[j + 1];
          }
          state->cumwidth[state->used] = 0;
          state->data[state->used--] = 0;
          recalc_cumwidth(state);
        }
        rv = true;
        break;
      default:
        // Handle letter keys.
        if (keycode >= 0x20 && keycode <= 0x7e && state->used < EBUF_SIZE - 1) {
          if (mod & (SDL_KMOD_SHIFT | SDL_KMOD_CAPS)) { // Handle capitals.
            keycode -= 32;
          }
          for (int j = state->used; j > state->cursorpos; j--) {
            state->data[j] = state->data[j - 1];
          }
          state->data[++state->used] = 0;
          state->data[state->cursorpos++] = keycode;
          recalc_cumwidth(state);
          state->pixpos = state->cumwidth[state->cursorpos];
          rv = true;
        }
        break;
    }
    // calculate xoff
    if (state->xoff + state->pixpos > net_width) {
      state->xoff = net_width - state->pixpos;
    } else if (state->xoff + state->pixpos < 0) {
      state->xoff = -state->pixpos;
    }
  }
  // Show clipped text
  if (state->used >= 0) {
    cairo_save(ctx);
    cairo_rectangle(ctx, left_top.x + offset, left_top.y, net_width, height);
    cairo_clip(ctx);
    cairo_move_to(ctx, left_top.x + offset + state->xoff, left_top.y + offset + 10);
    gui_use_fg();
    cairo_show_text(ctx, state->data);
    cairo_restore(ctx);
  }
  // show cursor.
  cairo_save(ctx);
  gui_use_acc();
  cairo_move_to(ctx, left_top.x + offset + state->xoff + state->pixpos, left_top.y + 4);
  cairo_rel_line_to(ctx, 0, height - 2 * offset);
  cairo_stroke(ctx);
  cairo_restore(ctx);
  return rv;
}
