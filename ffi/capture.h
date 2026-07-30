#ifndef CAPTURE_H
#define CAPTURE_H

#include "common.h"

#define CAPTURE_DISPATCH_TIMEOUT                                               \
  (dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC))

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

Vector2 size_capture(void);

bool load_capture(Vector2 position, Vector2 size, Capture *capture);

void free_capture(Capture *capture);

#endif // CAPTURE_H
