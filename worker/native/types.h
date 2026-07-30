#ifndef TYPES_H
#define TYPES_H

#include <stdbool.h>
#include <stdint.h>

// [--------------------------------------------------------------] //
// > Data Structures                                              < //
// [--------------------------------------------------------------] //

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef int8_t i8;
typedef int16_t i16;
typedef int32_t i32;
typedef int64_t i64;

typedef float f32;
typedef double f64;

typedef struct {
  f64 x;
  f64 y;
} Point2D;

#endif // TYPES_H
