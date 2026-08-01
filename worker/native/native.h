#ifndef NATIVE_H
#define NATIVE_H

#include "types.h"

// [--------------------------------------------------------------] //
// > Constants                                                    < //
// [--------------------------------------------------------------] //

#define CAPTURE_TIMEOUT (dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC))

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

// [--------------------------------------------------------------] //
// > Function Declarations                                        < //
// [--------------------------------------------------------------] //

bool init_capture(void);

bool size_capture(Point2D *point);

bool load_capture(Point2D position, Point2D size, Capture *capture);

void free_capture(Capture *capture);

bool load_paste(const char *content);

#endif // NATIVE_H
