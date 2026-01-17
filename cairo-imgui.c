// file: cairo-imgui.c
// vim:fileencoding=utf-8:ft=c:tabstop=2
// This is free and unencumbered software released into the public domain.
//
// Author: R.F. Smith <rsmith@xs4all.nl>
// SPDX-License-Identifier: Unlicense
// Created: 2025-08-26 14:04:09 +0200
// Last modified: 2026-01-17T21:51:29+0100

#include "cairo-imgui.h"
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <cairo/cairo.h>
#include <SDL3/SDL.h>
#include "SDL3/SDL_events.h"
#include "SDL3/SDL_keycode.h"

static double m_width, m_height;

void gui_begin(SDL_Renderer *renderer, SDL_Texture *texture, GUI_context *out)
{
  assert(renderer);
  assert(texture);
  assert(out);
  void *pixels;
  int pitch;
  int w, h;
  out->renderer = renderer;
  out->texture = texture;
  SDL_GetCurrentRenderOutputSize(renderer, &w, &h);
  // Create cairo surface which maps to the SDL texture.
  SDL_LockTexture(texture, 0, &pixels, &pitch);
  out->surface = cairo_image_surface_create_for_data(
                   (char unsigned*)pixels, CAIRO_FORMAT_ARGB32, w, h, pitch);
  // Create cairo context to draw on the surface.
  out->ctx = cairo_create(out->surface);
  // Set color to background, fill the surface)
  cairo_set_source_rgb(out->ctx, out->bg.r, out->bg.g, out->bg.b);
  cairo_paint(out->ctx);
  // Set font size
  cairo_set_font_size(out->ctx, 14.0);
  // Determine the size of a capital M.
  cairo_text_extents_t ext;
  cairo_text_extents(out->ctx, "M", &ext);
  m_width = ext.width;
  m_height = ext.height;
  out->counter = 1;
}

void gui_end(GUI_context *ctx)
{
  assert(ctx);
  ctx->button_released = false;
  ctx->keycode = 0;
  ctx->mod = 0;
  // Clean up
  cairo_destroy(ctx->ctx);
  cairo_surface_destroy(ctx->surface);
  ctx->surface = 0;
  SDL_UnlockTexture(ctx->texture);
  SDL_RenderTexture(ctx->renderer, ctx->texture, 0, 0);
  SDL_RenderPresent(ctx->renderer);
  ctx->maxid = ctx->counter;
}

void gui_theme_light(GUI_context *ctx)
{
  ctx->bg = (GUI_rgb) {
    0.992157, 0.964706, 0.890196
  }; // Base3 #fdf6e3
  ctx->fg = (GUI_rgb) {
    0.345098, 0.431373, 0.458824
  }; // Base01 #586e75
  ctx->acc = (GUI_rgb) {
    0.14902, 0.545098, 0.823529
  }; // Blue #268bd2
}

void gui_theme_dark(GUI_context *ctx)
{
  ctx->bg = (GUI_rgb) {
    0.027451, 0.211765, 0.258824
  }; // Base02 #073642
  ctx->fg = (GUI_rgb) {
    0.576471, 0.631373, 0.631373
  }; // Base1 #93a1a1
  ctx->acc = (GUI_rgb) {
    0.14902, 0.545098, 0.823529
  }; // Blue #268bd2
}

SDL_AppResult gui_process_events(GUI_context *ctx, SDL_Event *event)
{
  int w, h;
  switch (event->type) {
    case SDL_EVENT_WINDOW_RESIZED:
      // Resize the texture if the window size changes.
      SDL_DestroyTexture(ctx->texture);
      SDL_GetWindowSize(SDL_GetRenderWindow(ctx->renderer), &w, &h);
      ctx->texture = SDL_CreateTexture(ctx->renderer, SDL_PIXELFORMAT_ARGB8888,
                                       SDL_TEXTUREACCESS_STREAMING, w, h);
      break;
    case SDL_EVENT_QUIT:
      return SDL_APP_SUCCESS;
      break;
    case SDL_EVENT_KEY_DOWN:
      if (event->key.key == 'q' || event->key.key == SDLK_ESCAPE) {
        return SDL_APP_SUCCESS;
      } else if (event->key.key == SDLK_TAB) {
        if (event->key.mod & (SDL_KMOD_LSHIFT|SDL_KMOD_RSHIFT)) {
          ctx->id--;
          if (ctx->id < 0) {
            ctx->id = ctx->maxid;
          }
        } else {
          ctx->id++;
          if (ctx->id > ctx->maxid) {
            ctx->id = 1;
          }
        }
      } else {
        ctx->keycode = event->key.key;
        ctx->mod = event->key.mod;
      }
      break;
    case SDL_EVENT_MOUSE_MOTION:
      ctx->mouse_x = event->motion.x;
      ctx->mouse_y = event->motion.y;
      break;
    case SDL_EVENT_MOUSE_BUTTON_DOWN:
      ctx->button_pressed = true;
      ctx->button_released = false;
      break;
    case SDL_EVENT_MOUSE_BUTTON_UP:
      ctx->button_pressed = false;
      ctx->button_released = true;
      break;
    default:
      if (ctx->button_released) {
        ctx->button_released = false;
      }
      break;
  }
  return SDL_APP_CONTINUE;
}


bool gui_button(GUI_context *c, double x, double y, const char *label)
{
  assert(c);
  // All interactive widgets should get an ID by increasing the counter.
  int32_t id = c->counter++;
  double rv = false;
  double offset = 10.0;
  cairo_text_extents_t ext;
  cairo_text_extents(c->ctx, label, &ext);
  double width = 2*offset + ext.width;
  double height = 2*offset +ext.height;
  // Draw button outline.
  cairo_new_path(c->ctx);
  cairo_set_source_rgb(c->ctx, c->fg.r, c->fg.g, c->fg.b);
  cairo_rectangle(c->ctx, x, y, width, height);
  cairo_stroke(c->ctx);
  // draw/Fill inside if mouse is inside, or we have the highlight.
  if ((c->mouse_x >= x && (c->mouse_x - x) <= width &&
      c->mouse_y >= y && (c->mouse_y - y) <= height)|| c->id == id) {
    c->id = id;
    cairo_new_path(c->ctx);
    cairo_set_source_rgb(c->ctx, c->acc.r, c->acc.g, c->acc.b);
    cairo_rectangle(c->ctx, x+1, y+1, width-2, height-2);
    if (c->button_pressed) {
      cairo_fill(c->ctx);
    } else {
      cairo_stroke(c->ctx);
    }
    if (c->button_released || c->keycode == SDLK_RETURN) {
      rv = true;
    }
  }
  // Draw the label
  cairo_new_path(c->ctx);
  cairo_set_source_rgb(c->ctx, c->fg.r, c->fg.g, c->fg.b);
  cairo_move_to(c->ctx, x + offset, y+offset+ext.height);
  cairo_show_text(c->ctx, label);
  cairo_fill(c->ctx);
  return rv;
}

void gui_label(GUI_context *c, double x, double y, const char *label)
{
  assert(c);
  // Labels don't interact, so they have no id.
  cairo_text_extents_t ext;
  cairo_text_extents(c->ctx, label, &ext);
  // Draw the label
  cairo_new_path(c->ctx);
  cairo_set_source_rgb(c->ctx, c->fg.r, c->fg.g, c->fg.b);
  cairo_move_to(c->ctx, x, y+ext.height);
  cairo_show_text(c->ctx, label);
  cairo_fill(c->ctx);
}

bool gui_checkbox(GUI_context *c, double x, double y, const char *label, bool *state)
{
  assert(c);
  int32_t id = c->counter++;
  double rv = false;
  double offset = 5.0;
  double boxsize = m_width>m_height?m_width:m_height;
  cairo_text_extents_t ext;
  cairo_text_extents(c->ctx, label, &ext);
  double width = 2*offset + ext.width + boxsize;
  double height = 2*offset + ext.height>boxsize?ext.height:boxsize;
  // Draw checkbox outline.
  cairo_new_path(c->ctx);
  cairo_set_source_rgb(c->ctx, c->fg.r, c->fg.g, c->fg.b);
  cairo_rectangle(c->ctx, x, y, boxsize, boxsize);
  cairo_stroke(c->ctx);
  // draw/Fill inside if mouse is inside, or we have the highlight.
  if ((c->mouse_x >= x && (c->mouse_x - x) <= width &&
      c->mouse_y >= y && (c->mouse_y - y) <= height)|| c->id == id) {
    c->id = id;
    cairo_new_path(c->ctx);
    cairo_set_source_rgb(c->ctx, c->acc.r, c->acc.g, c->acc.b);
    cairo_rectangle(c->ctx, x+1, y+1, boxsize-2, boxsize-2);
    if (c->button_pressed) {
      cairo_fill(c->ctx);
    } else {
      cairo_stroke(c->ctx);
    }
    if (c->button_released || c->keycode == SDLK_RETURN) {
      rv = true;
      *state = !*state;
    }
  }
  // Draw selected mark if needed.
  if (*state) {
    cairo_new_path(c->ctx);
    cairo_set_source_rgb(c->ctx, c->fg.r, c->fg.g, c->fg.b);
    cairo_move_to(c->ctx, x, y);
    cairo_rel_line_to(c->ctx, boxsize, boxsize);
    cairo_rel_move_to(c->ctx, 0, -boxsize);
    cairo_rel_line_to(c->ctx, -boxsize, boxsize);
    cairo_stroke(c->ctx);
  }
  // Draw the label
  cairo_new_path(c->ctx);
  cairo_set_source_rgb(c->ctx, c->fg.r, c->fg.g, c->fg.b);
  cairo_move_to(c->ctx, x + boxsize + offset, y+boxsize/2+ext.height/2);
  cairo_show_text(c->ctx, label);
  cairo_fill(c->ctx);
  return rv;
}

bool gui_radiobuttons(GUI_context *c, double x, double y, int nlabels,
                      const char *labels[nlabels], int *state)
{
  assert(c);
  assert(labels);
  assert(nlabels > 0);
  int32_t id = c->counter++;
  double rv = false;
  double offset = 5.0;
  //double boxsize = 14.0;
  double boxsize = (m_width>m_height?m_width:m_height)*1.5;
  double width, height;
  double heights[nlabels];
  double exty[nlabels];
  cairo_text_extents_t ext = {0};
  cairo_text_extents(c->ctx, labels[0], &ext);
  width = ext.width;
  height = ext.height;
  heights[0] = ext.height>boxsize?ext.height:boxsize;
  exty[0] = ext.height;
  for (int k = 1; k < nlabels; k++) {
    cairo_text_extents(c->ctx, labels[k], &ext);
    heights[k] = ext.height>boxsize?ext.height:boxsize;
    exty[k] = ext.height;
    if (width < ext.width) {
      width = ext.width;
    }
    height += heights[k];
  }
  width += 2*offset + boxsize;
  height += 2*offset;
  // Draw the buttons.
  int cury = y + boxsize/2;
  int curx = x + boxsize/2;
  // Draw the buttons and the selected one
  cairo_set_source_rgb(c->ctx, c->fg.r, c->fg.g, c->fg.b);
  for (int k = 0; k < nlabels; k++) {
    cairo_new_path(c->ctx);
    cairo_arc(c->ctx, curx, cury, boxsize/2 - 2, 0.0, 2*M_PI);
    cairo_stroke(c->ctx);
    if (*state == k) {
      cairo_new_path(c->ctx);
      cairo_arc(c->ctx, curx, cury, boxsize/2 - 4, 0.0, 2*M_PI);
      cairo_fill(c->ctx);
    }
    cury += heights[k];
  }
  // Draw the labels
  cury = y + offset;
  curx = x + boxsize + offset;
  cairo_new_path(c->ctx);
  cairo_set_source_rgb(c->ctx, c->fg.r, c->fg.g, c->fg.b);
  for (int k = 0; k < nlabels; k++) {
    cairo_move_to(c->ctx, curx, cury+exty[k]/2);
    cairo_show_text(c->ctx, labels[k]);
    cury += heights[k];
  }
  cairo_fill(c->ctx);
  // draw/Fill inside if mouse is inside, or we have the highlight.
  if ((c->mouse_x >= x && (c->mouse_x - x) <= width &&
      c->mouse_y >= y && (c->mouse_y - y) <= height)|| c->id == id) {
    c->id = id;
    cairo_new_path(c->ctx);
    cairo_set_source_rgb(c->ctx, c->acc.r, c->acc.g, c->acc.b);
    cury = y + boxsize/2;
    curx = x + boxsize/2;
    for (int k = 0; k < nlabels; k++) {
      if ((fabs((double)c->mouse_y - cury) < exty[k]/2)) {
        // This is the label!
        cairo_new_path(c->ctx);
        cairo_arc(c->ctx, curx, cury, boxsize/2 - 3, 0.0, 2*M_PI);
        if (c->button_pressed) {
          cairo_fill(c->ctx);
        } else {
          cairo_stroke(c->ctx);
        }
        if (c->button_released || c->keycode == SDLK_RETURN) {
          rv = true;
          *state = k;
        } else if (c->keycode == SDLK_UP) {
          *state = --k;
          if (*state < 0) {
            *state = nlabels-1;
          }
        } else if (c->keycode == SDLK_DOWN) {
          *state = ++k;
          if (*state == nlabels) {
            *state = 0;
          }
        }
        break;
      };
      cury += heights[k];
    }
  }
  return rv;
}

void gui_colorsample(GUI_context *c, const double x, const double y,
                     const double w, const double h, const GUI_rgb *state)
{
  assert(c);
  assert(state);
  cairo_new_path(c->ctx);
  cairo_set_source_rgb(c->ctx, state->r, state->g, state->b);
  cairo_rectangle(c->ctx, x, y, w, h);
  cairo_fill(c->ctx);
}

bool gui_slider(GUI_context *c, const double x, const double y, int *state)
{
  assert(c);
  assert(state);
  int32_t id = c->counter++;
  bool changed = false;
  const double xsize = 20.0;
  const double ysize = 10.0;
  const double offset = 4.0;
  const double width = 255.0 + xsize + 2*offset;
  const double height = ysize + 2*offset;
  // Draw outside rectangle
  cairo_new_path(c->ctx);
  cairo_set_source_rgb(c->ctx, c->fg.r, c->fg.g, c->fg.b);
  cairo_rectangle(c->ctx, x, y, width, height);
  cairo_stroke(c->ctx);
  // draw/Fill inside if mouse is inside, or we have the highlight.
  if ((c->mouse_x >= x && (c->mouse_x - x) <= width &&
      c->mouse_y >= y && (c->mouse_y - y) <= height)|| c->id == id) {
    c->id = id;
    // draw inside if mouse is inside.
    cairo_new_path(c->ctx);
    cairo_set_source_rgb(c->ctx, c->acc.r, c->acc.g, c->acc.b);
    cairo_rectangle(c->ctx, x+2, y+2, width-4, height-4);
    cairo_stroke(c->ctx);
    // Update state if mouse is inside and button is pressed
    if (c->button_pressed || c->keycode == SDLK_RETURN) {
      int newstate = round(c->mouse_x - x - offset - xsize/2.0);
      if (newstate != *state) {
        *state = newstate;
        changed = true;
      }
    }
    if (c->keycode == SDLK_LEFT) {
      (*state)--;
      changed = true;
    } else if (c->keycode == SDLK_RIGHT) {
      (*state)++;
      changed = true;
    } else if (c->keycode == SDLK_HOME) {
      *state = 0;
      changed = true;
    }  else if (c->keycode == SDLK_END) {
      *state = 255;
      changed = true;
    }
  }
  // Clamp state within allowed range.
  if (*state < 0) {
    *state = 0;
  } else if (*state > 255) {
    *state = 255;
  }
  // Draw slider
  double sliderpos = x + (double)*state + offset;
  cairo_new_path(c->ctx);
  cairo_set_source_rgb(c->ctx, c->fg.r, c->fg.g, c->fg.b);
  cairo_rectangle(c->ctx, sliderpos, y + offset, xsize, ysize);
  cairo_fill(c->ctx);
  return changed;
}

bool gui_ispinner(GUI_context *c, const double x, const double y,
                 int32_t min, int32_t max, int32_t*state)
{
  assert(c);
  assert(state);
  assert(max > min);
  int32_t id = c->counter++;
  bool rv = false;
  // Determine the amount of characters needed
  double maxw = ceil(log10(fabs((double)max))) * m_width;
  const double offset = 6.0;
  const double boxsize = 12.0;
  double width = maxw + 2 * offset + 2*boxsize;
  double height = m_height + 2 * offset;
  // Draw the outline.
  cairo_new_path(c->ctx);
  cairo_set_source_rgb(c->ctx, c->fg.r, c->fg.g, c->fg.b);
  cairo_rectangle(c->ctx, x, y, width, height);
  cairo_stroke(c->ctx);
  // Draw the spinner buttons.
  cairo_new_path(c->ctx);
  cairo_set_source_rgb(c->ctx, c->fg.r, c->fg.g, c->fg.b);
  cairo_move_to(c->ctx, x+offset+maxw, y+offset+m_height);
  cairo_rel_line_to(c->ctx, boxsize, 0);
  cairo_rel_line_to(c->ctx, -boxsize/2, -boxsize);
  cairo_rel_line_to(c->ctx, -boxsize/2, boxsize);
  cairo_close_path(c->ctx);
  cairo_fill(c->ctx);
  cairo_new_path(c->ctx);
  cairo_set_source_rgb(c->ctx, c->fg.r, c->fg.g, c->fg.b);
  cairo_move_to(c->ctx, x+offset+maxw+boxsize, y+offset);
  cairo_rel_line_to(c->ctx, boxsize, 0);
  cairo_rel_line_to(c->ctx, -boxsize/2, boxsize);
  cairo_rel_line_to(c->ctx, -boxsize/2, -boxsize);
  cairo_close_path(c->ctx);
  cairo_fill(c->ctx);
  if ((c->mouse_x >= x && (c->mouse_x - x) <= width &&
      c->mouse_y >= y && (c->mouse_y - y) <= height)|| c->id == id) {
    c->id = id;
    // Draw inside accent if mouse is inside.
    cairo_new_path(c->ctx);
    cairo_set_source_rgb(c->ctx, c->acc.r, c->acc.g, c->acc.b);
    cairo_rectangle(c->ctx, x+2, y+2, width-4, height-4);
    cairo_stroke(c->ctx);
    if (c->button_pressed) {
      double xdist =  c->mouse_x - x - offset - maxw;
      if (xdist < boxsize) {
        (*state)++;
        rv = true;
      } else if (xdist > boxsize) {
        (*state)--;
        rv = true;
      }
    }
    // Update the value when up or down arrows are used.
    switch (c->keycode) {
      case SDLK_UP:
        (*state)++;
        rv = true;
        break;
      case SDLK_DOWN:
        (*state)--;
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
  cairo_text_extents(c->ctx, buf, &ext);
  cairo_new_path(c->ctx);
  cairo_set_source_rgb(c->ctx, c->fg.r, c->fg.g, c->fg.b);
  cairo_move_to(c->ctx, x+offset, y+offset+ext.height);
  cairo_show_text(c->ctx, buf);
  return rv;
}

bool gui_editbox(GUI_context *c, const double x, const double y, const double w,
                 GUI_editstate *state)
{
  assert(c);
  assert(state);
  int32_t id = c->counter++;
  const double offset = 6.0;
  double height = m_height + 2 * offset;
  bool rv = false;
  // Draw the outline.
  cairo_new_path(c->ctx);
  cairo_set_source_rgb(c->ctx, c->fg.r, c->fg.g, c->fg.b);
  cairo_rectangle(c->ctx, x, y, w, height);
  cairo_stroke(c->ctx);
  if ((c->mouse_x >= x && (c->mouse_x - x) <= w &&
      c->mouse_y >= y && (c->mouse_y - y) <= height)|| c->id == id) {
    c->id = id;
    // Draw inside accent if mouse is inside.
    cairo_new_path(c->ctx);
    cairo_set_source_rgb(c->ctx, c->acc.r, c->acc.g, c->acc.b);
    cairo_rectangle(c->ctx, x+2, y+2, w-4, height-4);
    cairo_stroke(c->ctx);
    // Process keys
    if (c->keycode == SDLK_LEFT) { // move cursor left
      if (state->cursorpos > 0) {
        state->cursorpos--;
      }
    } else if (c->keycode == SDLK_RIGHT) { // move cursor right
      if (state->cursorpos < state->used) {
        state->cursorpos++;
      }
    } else if (c->keycode >= 0x20 && c->keycode <= 0x7e) { // insert regular key.
      char keycode = (char)c->keycode;
      if (c->mod & (SDL_KMOD_SHIFT|SDL_KMOD_CAPS)) {  // Handle capitals.
        keycode -= 32;
      }
      if (state->cursorpos == state->used) {  // cursor at end
        state->data[state->used++] = keycode;
        state->cursorpos++;
      } else if (state->cursorpos < state->used) {  // cursor inside text
        for (int m = state->used; m >= state->cursorpos; m--) {
          state->data[m+1] = state->data[m];
        }
        state->data[state->cursorpos++] = keycode;
        state->used++;

      }
    } else if (c->keycode == SDLK_END) {
      state->cursorpos = state->used;
    } else if (c->keycode == SDLK_HOME) {
      state->cursorpos = 0;
    } else if (c->keycode == SDLK_BACKSPACE) {
      if (state->cursorpos > 0 && state->cursorpos <= state->used) {
        for (int move = state->cursorpos-1; move < state->used; move++) {
          state->data[move] = state->data[move+1];
        }
        state->data[state->used--] = 0;
        state->cursorpos--;
      }
    } else if (c->keycode == SDLK_DELETE) {
      if (state->cursorpos >= 0 && state->cursorpos <= state->used) {
        for (int move = state->cursorpos; move < state->used; move++) {
          state->data[move] = state->data[move+1];
        }
        state->data[state->used--] = 0;
        if (state->cursorpos > 0) {
          state->cursorpos--;
        }
      }
    }
    // fill the cumulative offset array
    double cum_off = 0.0;
    for (int j = 0; j < state->cursorpos; j++) {
      char str[2] = {0};
       cairo_text_extents_t ext;
      str[0] = state->data[j];
      cairo_text_extents(c->ctx, str, &ext);
      cum_off += ext.x_advance;
    }
    // TODO: draw the cursor position
    cairo_new_path(c->ctx);
    cairo_set_source_rgb(c->ctx, c->acc.r, c->acc.g, c->acc.b);
    cairo_move_to(c->ctx, x+offset+cum_off, y+offset);
    cairo_rel_line_to(c->ctx, 0, m_height);
    cairo_stroke(c->ctx);
  }
  // TODO: Draw the text, clip if longer than window.
  cairo_text_extents_t ext;
  cairo_text_extents(c->ctx, state->data, &ext);
  cairo_new_path(c->ctx);
  cairo_set_source_rgb(c->ctx, c->fg.r, c->fg.g, c->fg.b);
  cairo_move_to(c->ctx, x+offset, y+offset+ext.height);
  cairo_show_text(c->ctx, state->data);

  return rv;
}

