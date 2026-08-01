#include "native.h"

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>

// [--------------------------------------------------------------] //
// > Global Variables                                             < //
// [--------------------------------------------------------------] //

static bool capture_ready = false;

static SCDisplay *capture_display = NULL;
static CGFloat capture_factor = 1.0;

// [--------------------------------------------------------------] //
// > Forward Declarations                                         < //
// [--------------------------------------------------------------] //

static bool image_to_rgba(CGImageRef image, void **out_pixels, u64 *out_length,
                          u64 *out_width, u64 *out_height, u64 *out_stride);

// [--------------------------------------------------------------] //
// > Function Implementations                                     < //
// [--------------------------------------------------------------] //

bool init_capture(void) {
  __block bool success = true;

  if (capture_ready) {
    return success;
  }

  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

  [SCShareableContent
      getShareableContentWithCompletionHandler:^(
          SCShareableContent *_Nullable content, NSError *_Nullable error) {
        if (error || !content || content.displays.count <= 0) {
          success = false;
          dispatch_semaphore_signal(semaphore);
          return;
        }

        CGDirectDisplayID main_display_id = CGMainDisplayID();
        SCDisplay *target_display = content.displays.firstObject;

        for (SCDisplay *candidate in content.displays) {
          if (candidate.displayID == main_display_id) {
            target_display = candidate;
            break;
          }
        }

        CGFloat scale_factor = 1.0;
        for (NSScreen *screen in NSScreen.screens) {
          NSNumber *screen_id = screen.deviceDescription[@"NSScreenNumber"];
          if (screen_id.unsignedIntValue == target_display.displayID) {
            scale_factor = screen.backingScaleFactor;
            break;
          }
        }

        capture_display = target_display;
        capture_factor = scale_factor;

        dispatch_semaphore_signal(semaphore);
      }];

  dispatch_semaphore_wait(semaphore, CAPTURE_TIMEOUT);

  capture_ready = success;
  return success;
}

bool size_capture(Point2D *point) {
  if (!capture_ready) {
    return false;
  }

  point->x = capture_display.width;
  point->y = capture_display.height;

  return true;
}

bool load_capture(Point2D position, Point2D size, Capture *capture) {
  if (!capture_ready) {
    return false;
  }

  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

  __block void *pixels = NULL;

  __block u64 length = 0;
  __block u64 width = 0;
  __block u64 height = 0;
  __block u64 stride = 0;

  SCContentFilter *filter =
      [[SCContentFilter alloc] initWithDisplay:capture_display
                              excludingWindows:@[]];

  SCStreamConfiguration *config = [[SCStreamConfiguration alloc] init];

  config.sourceRect = CGRectMake(position.x, position.y, size.x, size.y);
  config.width = (NSInteger)lround(size.x * capture_factor);
  config.height = (NSInteger)lround(size.y * capture_factor);
  config.showsCursor = NO;

  [SCScreenshotManager
      captureImageWithFilter:filter
               configuration:config
           completionHandler:^(CGImageRef image, NSError *error) {
             if (error || !image) {
               dispatch_semaphore_signal(semaphore);
               return;
             }

             void *temporary_pixels = NULL;

             u64 temporary_length = 0;
             u64 temporary_width = 0;
             u64 temporary_height = 0;
             u64 temporary_stride = 0;

             if (image_to_rgba(image, &temporary_pixels, &temporary_length,
                               &temporary_width, &temporary_height,
                               &temporary_stride)) {
               pixels = temporary_pixels;
               length = temporary_length;
               width = temporary_width;
               height = temporary_height;
               stride = temporary_stride;
             }

             dispatch_semaphore_signal(semaphore);
           }];

  u64 timeout = dispatch_semaphore_wait(semaphore, CAPTURE_TIMEOUT);
  if (timeout != 0) {
    return false;
  }

  capture->data = pixels;
  capture->length = length;
  capture->width = width;
  capture->height = height;
  capture->stride = stride;

  return true;
}

void free_capture(Capture *capture) {
  if (!capture) {
    return;
  }

  if (capture->data) {
    free(capture->data);
    capture->data = NULL;
  }
}

bool load_paste(const char *content) {
  NSString *string = [NSString stringWithUTF8String:content];
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];

  [pasteboard clearContents];
  return [pasteboard setString:string forType:NSPasteboardTypeString];
}

// [--------------------------------------------------------------] //
// > Internal Functions                                           < //
// [--------------------------------------------------------------] //

static bool image_to_rgba(CGImageRef image, void **out_pixels, u64 *out_length,
                          u64 *out_width, u64 *out_height, u64 *out_stride) {
  const u64 width = CGImageGetWidth(image);
  const u64 height = CGImageGetHeight(image);
  const u64 per_pixel = 4;
  const u64 stride = width * per_pixel;
  const u64 length = stride * height;

  void *pixels = malloc(length);
  if (!pixels) {
    return false;
  }

  CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
  if (!color_space) {
    free(pixels);
    return false;
  }

  CGContextRef context = CGBitmapContextCreate(
      pixels, width, height, 8, stride, color_space,
      kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

  CGColorSpaceRelease(color_space);

  if (!context) {
    free(pixels);
    return false;
  }

  CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);

  CGContextRelease(context);

  *out_pixels = pixels;
  *out_length = length;
  *out_width = width;
  *out_height = height;
  *out_stride = stride;

  return true;
}
