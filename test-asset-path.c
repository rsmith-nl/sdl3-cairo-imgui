// file: test-asset-path.c
// Test program to verify asset path loading works correctly
// This is free and unencumbered software released into the public domain.

#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <cairo/cairo.h>

#include <stdio.h>
#include <stdbool.h>

typedef struct {
  SDL_Window *window;
  SDL_Renderer *renderer;
  SDL_Texture *texture;
  cairo_surface_t *image_surface;
  int image_width;
  int image_height;
  bool image_loaded;
} State;

SDL_AppResult SDL_AppInit(void **appstate, int argc, char **argv)
{
  (void)argc;
  (void)argv;
  
  static State s = {0};
  *appstate = &s;
  
  if (!SDL_Init(SDL_INIT_VIDEO)) {
    SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
    return SDL_APP_FAILURE;
  }
  
  // Try to load the test image from assets/
  const char *image_path = "assets/test-image.png";
  printf("=== Asset Path Test ===\n");
  printf("Attempting to load: %s\n", image_path);
  printf("Current working directory should be project root\n\n");
  
  s.image_surface = cairo_image_surface_create_from_png(image_path);
  cairo_status_t status = cairo_surface_status(s.image_surface);
  
  if (status != CAIRO_STATUS_SUCCESS) {
    printf("❌ FAILED to load image!\n");
    printf("Cairo error: %s\n", cairo_status_to_string(status));
    printf("\nThis means the working directory is NOT set to project root.\n");
    printf("Expected path: <project-root>/assets/test-image.png\n");
    return SDL_APP_FAILURE;
  }
  
  s.image_width = cairo_image_surface_get_width(s.image_surface);
  s.image_height = cairo_image_surface_get_height(s.image_surface);
  s.image_loaded = true;
  
  printf("✅ SUCCESS! Image loaded successfully!\n");
  printf("Image size: %dx%d pixels\n", s.image_width, s.image_height);
  printf("\nAsset path is working correctly!\n");
  printf("Working directory is properly set to project root.\n\n");
  
  // Create window sized to fit the image
  int win_width = s.image_width > 800 ? 800 : s.image_width;
  int win_height = s.image_height > 600 ? 600 : s.image_height;
  
  if (!SDL_CreateWindowAndRenderer("Asset Path Test - Image Loaded Successfully", 
                                   win_width, win_height, 0,
                                   &s.window, &s.renderer)) {
    SDL_Log("Couldn't create window and renderer: %s", SDL_GetError());
    return SDL_APP_FAILURE;
  }
  
  SDL_SetRenderVSync(s.renderer, SDL_RENDERER_VSYNC_ADAPTIVE);
  
  // Create texture for rendering
  s.texture = SDL_CreateTexture(s.renderer, SDL_PIXELFORMAT_ARGB8888,
                                SDL_TEXTUREACCESS_STREAMING, 
                                win_width, win_height);
  
  printf("Close the window to exit the test.\n");
  printf("=====================================\n");
  
  return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void *appstate)
{
  State *s = appstate;
  
  if (!s->image_loaded) {
    return SDL_APP_SUCCESS;
  }
  
  // Lock texture to get pixel data
  void *pixels;
  int pitch;
  SDL_LockTexture(s->texture, NULL, &pixels, &pitch);
  
  // Get texture dimensions
  float w_f, h_f;
  SDL_GetTextureSize(s->texture, &w_f, &h_f);
  int w = (int)w_f;
  int h = (int)h_f;
  
  // Create Cairo surface from texture pixels
  cairo_surface_t *surface = cairo_image_surface_create_for_data(
    pixels, CAIRO_FORMAT_ARGB32, w, h, pitch);
  
  cairo_t *cr = cairo_create(surface);
  
  // Clear background
  cairo_set_source_rgb(cr, 0.2, 0.2, 0.25);
  cairo_paint(cr);
  
  // Draw the loaded image (scaled to fit if needed)
  double scale_x = (double)w / s->image_width;
  double scale_y = (double)h / s->image_height;
  double scale = (scale_x < scale_y) ? scale_x : scale_y;
  
  if (scale > 1.0) scale = 1.0; // Don't upscale
  
  cairo_save(cr);
  cairo_scale(cr, scale, scale);
  cairo_set_source_surface(cr, s->image_surface, 0, 0);
  cairo_paint(cr);
  cairo_restore(cr);
  
  // Draw success message
  cairo_set_source_rgb(cr, 0.0, 1.0, 0.0);
  cairo_select_font_face(cr, "Sans", CAIRO_FONT_SLANT_NORMAL, 
                         CAIRO_FONT_WEIGHT_BOLD);
  cairo_set_font_size(cr, 20);
  cairo_move_to(cr, 10, h - 10);
  cairo_show_text(cr, "[OK] Asset path working correctly!");
  
  cairo_destroy(cr);
  cairo_surface_destroy(surface);
  
  SDL_UnlockTexture(s->texture);
  
  // Render to screen
  SDL_RenderClear(s->renderer);
  SDL_RenderTexture(s->renderer, s->texture, NULL, NULL);
  SDL_RenderPresent(s->renderer);
  
  return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event)
{
  (void)appstate;
  
  if (event->type == SDL_EVENT_QUIT) {
    return SDL_APP_SUCCESS;
  }
  
  return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void *appstate, SDL_AppResult result)
{
  State *s = appstate;
  (void)result;
  
  if (s->image_surface) {
    cairo_surface_destroy(s->image_surface);
  }
  if (s->texture) {
    SDL_DestroyTexture(s->texture);
  }
  if (s->renderer) {
    SDL_DestroyRenderer(s->renderer);
  }
  if (s->window) {
    SDL_DestroyWindow(s->window);
  }
  SDL_Quit();
  
  printf("\nTest completed.\n");
}
