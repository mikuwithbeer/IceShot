#ifndef NATIVE_H
#define NATIVE_H

#include "types.h"

// [--------------------------------------------------------------] //
// > Data Structures                                              < //
// [--------------------------------------------------------------] //

typedef struct {
  void *data;

  u64 length;
  u64 width;
  u64 height;
  u64 stride;
} Capture;

typedef struct {
  void *data;

  u64 width;
  u64 height;
} Image;

// [--------------------------------------------------------------] //
// > Function Declarations                                        < //
// [--------------------------------------------------------------] //

bool init_capture(void);

bool size_capture(Point2D *point);

bool load_capture(Point2D position, Point2D size, Capture *capture);

void free_capture(Capture *capture);

bool crop_image(Image image, Area2D area, Capture *capture);

bool copy_value(const char *content);

bool copy_image(Image image);

bool copy_vision(Image image, bool is_barcode);

bool share_image(Image image, const char *token);

bool dark_mode();

void error_box(const char *content);

void navigate_box(const char *path);

// [--------------------------------------------------------------] //
// > Internal Functions                                           < //
// [--------------------------------------------------------------] //

static inline u64 pixel_stride(u64 width) { return width * 4; }

static inline u64 pixel_length(u64 width, u64 height) {
  return pixel_stride(width) * height;
}

static inline u8 *image_pixel(Image image, u64 x, u64 y) {
  return (u8 *)image.data + y * pixel_stride(image.width) + x * 4;
}

static inline u8 *capture_row(const Capture *capture, u64 y) {
  return (u8 *)capture->data + y * capture->stride;
}

#endif // NATIVE_H
