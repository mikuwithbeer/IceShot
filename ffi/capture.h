#ifndef CAPTURE_H
#define CAPTURE_H

#include "common.h"

typedef struct {
  void *data;

  u64 length;
  u64 width;
  u64 height;
  u64 stride;
} Capture;

typedef struct {
  f64 x;
  f64 y;
} Vector2;

bool init_capture(void);

Capture load_capture(Vector2 position, Vector2 size);

void free_capture(Capture *capture);

#endif // CAPTURE_H
