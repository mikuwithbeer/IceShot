#include "native.h"

#import <AppKit/AppKit.h>
#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>
#import <Vision/Vision.h>

// [--------------------------------------------------------------] //
// > Global Variables                                             < //
// [--------------------------------------------------------------] //

static bool capture_ready = false;

static SCDisplay *capture_display = NULL;
static CGFloat capture_factor = 1.0;

// [--------------------------------------------------------------] //
// > Forward Declarations                                         < //
// [--------------------------------------------------------------] //

static bool alloc_capture(Capture *capture, u64 width, u64 height);

static bool image_to_capture(CGImageRef image, Capture *out);

static NSBitmapImageRep *image_to_bitmap(Image image);

// [--------------------------------------------------------------] //
// > Function Implementations                                     < //
// [--------------------------------------------------------------] //

bool init_capture(void) {
  @autoreleasepool {
    __block bool success = true;

    if (capture_ready) {
      return success;
    }

    if (!CGPreflightScreenCaptureAccess()) {
      bool granted = CGRequestScreenCaptureAccess();
      if (!granted) {
        return false;
      }
    }

    __auto_type semaphore = dispatch_semaphore_create(0);

    [SCShareableContent
        getShareableContentWithCompletionHandler:^(
            SCShareableContent *_Nullable content, NSError *_Nullable error) {
          if (error || !content || content.displays.count <= 0) {
            success = false;
            dispatch_semaphore_signal(semaphore);
            return;
          }

          __auto_type main_display_id = CGMainDisplayID();
          __auto_type target_display = content.displays.firstObject;

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

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    if (!success || !capture_display) {
      return false;
    }

    capture_ready = true;
    return true;
  }
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
  @autoreleasepool {
    if (!capture_ready || !capture) {
      return false;
    }

    __auto_type semaphore = dispatch_semaphore_create(0);
    __block Capture result = {0};

    __auto_type filter =
        [[SCContentFilter alloc] initWithDisplay:capture_display
                                excludingWindows:@[]];

    __auto_type config = [[SCStreamConfiguration alloc] init];
    config.sourceRect = CGRectMake(position.x, position.y, size.x, size.y);
    config.width = (NSInteger)lround(size.x * capture_factor);
    config.height = (NSInteger)lround(size.y * capture_factor);
    config.showsCursor = NO;

    [SCScreenshotManager
        captureImageWithFilter:filter
                 configuration:config
             completionHandler:^(CGImageRef image, NSError *error) {
               if (!error && image) {
                 image_to_capture(image, &result);
               }
               dispatch_semaphore_signal(semaphore);
             }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    if (!result.data) {
      return false;
    }

    *capture = result;
    return true;
  }
}

void free_capture(Capture *capture) {
  if (!capture) {
    return;
  }

  if (capture->data) {
    munmap(capture->data, capture->length);
  }

  capture->data = NULL;
  capture->length = 0;
  capture->width = 0;
  capture->height = 0;
  capture->stride = 0;
}

bool crop_image(Image image, Area2D area, Capture *capture) {
  @autoreleasepool {
    if (!capture || !image.data || image.width == 0 || image.height == 0) {
      return false;
    }

    if (!isfinite(area.x) || !isfinite(area.y) || !isfinite(area.width) ||
        !isfinite(area.height)) {
      return false;
    }

    const double max_x = (double)image.width;
    const double max_y = (double)image.height;

    const double x0 =
        fmin(fmax(floor(fmin(area.x, area.x + area.width)), 0), max_x);
    const double y0 =
        fmin(fmax(floor(fmin(area.y, area.y + area.height)), 0), max_y);
    const double x1 =
        fmin(fmax(ceil(fmax(area.x, area.x + area.width)), 0), max_x);
    const double y1 =
        fmin(fmax(ceil(fmax(area.y, area.y + area.height)), 0), max_y);

    Capture cropped = {0};
    if (!alloc_capture(&cropped, (u64)(x1 - x0), (u64)(y1 - y0))) {
      return false;
    }

    for (u64 row = 0; row < cropped.height; row++) {
      memcpy(capture_row(&cropped, row),
             image_pixel(image, (u64)x0, (u64)y0 + row), cropped.stride);
    }

    *capture = cropped;
    return true;
  }
}

bool copy_value(const char *content) {
  @autoreleasepool {
    __auto_type string = [NSString stringWithUTF8String:content];
    __auto_type pasteboard = [NSPasteboard generalPasteboard];

    [pasteboard clearContents];
    return [pasteboard setString:string forType:NSPasteboardTypeString];
  }
}

bool copy_image(Image image) {
  @autoreleasepool {
    __auto_type representation = image_to_bitmap(image);
    if (!representation) {
      return false;
    }

    __auto_type ns_image =
        [[NSImage alloc] initWithSize:NSMakeSize(image.width, image.height)];
    [ns_image addRepresentation:representation];

    __auto_type pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];

    return [pasteboard writeObjects:@[ ns_image ]];
  }
}

bool copy_vision(Image image, bool is_barcode) {
  @autoreleasepool {
    __auto_type representation = image_to_bitmap(image);
    if (!representation) {
      return false;
    }

    __auto_type cg_image = [representation CGImage];
    if (!cg_image) {
      return false;
    }

    __block __auto_type recognized = [NSMutableString string];
    __auto_type requests = [NSMutableArray array];

    if (!is_barcode) {
      __auto_type text_request = [[VNRecognizeTextRequest alloc]
          initWithCompletionHandler:^(VNRequest *request, NSError *error) {
            if (error) {
              return;
            }

            for (VNRecognizedTextObservation *observation in request.results) {
              VNRecognizedText *top_candidate =
                  [[observation topCandidates:1] firstObject];
              if (top_candidate) {
                [recognized appendFormat:@"%@\n", top_candidate.string];
              }
            }
          }];

      text_request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
      [requests addObject:text_request];
    } else {
      __auto_type barcode_request = [[VNDetectBarcodesRequest alloc]
          initWithCompletionHandler:^(VNRequest *request, NSError *error) {
            if (error) {
              return;
            }

            for (VNBarcodeObservation *observation in request.results) {
              if (observation.payloadStringValue) {
                [recognized
                    appendFormat:@"%@\n", observation.payloadStringValue];
              }
            }
          }];

      [requests addObject:barcode_request];
    }

    if (requests.count == 0) {
      return false;
    }

    __auto_type request_handler =
        [[VNImageRequestHandler alloc] initWithCGImage:cg_image options:@{}];

    NSError *error = nil;
    if (![request_handler performRequests:requests error:&error]) {
      return false;
    }

    __auto_type final = [recognized
        stringByTrimmingCharactersInSet:[NSCharacterSet
                                            whitespaceAndNewlineCharacterSet]];

    if (final.length == 0) {
      return false;
    }

    __auto_type pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];

    return [pasteboard setString:final forType:NSPasteboardTypeString];
  }
}

bool share_image(Image image, const char *token) {
  @autoreleasepool {
    if (!token) {
      return false;
    }

    __auto_type representation = image_to_bitmap(image);
    if (!representation) {
      return false;
    }

    __auto_type png_data =
        [representation representationUsingType:NSBitmapImageFileTypePNG
                                     properties:@{}];
    if (!png_data) {
      return false;
    }

    __auto_type url = [NSURL
        URLWithString:
            [NSString stringWithFormat:@"https://api.imgbb.com/1/upload?key=%s",
                                       token]];

    __auto_type request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 10;

    __auto_type boundary =
        [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];

    [request setValue:[NSString
                          stringWithFormat:@"multipart/form-data; boundary=%@",
                                           boundary]
        forHTTPHeaderField:@"Content-Type"];

    __auto_type body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary]
                         dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: form-data; name=\"image\"; "
                      @"filename=\"image.png\"\r\n"
                         dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/png\r\n\r\n"
                         dataUsingEncoding:NSUTF8StringEncoding]];

    [body appendData:png_data];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary]
                         dataUsingEncoding:NSUTF8StringEncoding]];

    request.HTTPBody = body;

    __auto_type semaphore = dispatch_semaphore_create(0);

    __block bool success = false;
    __block NSString *result = nil;

    __auto_type session = [NSURLSession sharedSession];
    __auto_type task = [session
        dataTaskWithRequest:request
          completionHandler:^(NSData *data, NSURLResponse *response,
                              NSError *error) {
            if (error || !data) {
              dispatch_semaphore_signal(semaphore);
              return;
            }

            NSError *parse_error = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data
                                                      options:0
                                                        error:&parse_error];
            if (parse_error || ![json isKindOfClass:[NSDictionary class]]) {
              dispatch_semaphore_signal(semaphore);
              return;
            }

            NSNumber *ok = json[@"success"];
            NSDictionary *payload = json[@"data"];

            if (ok.boolValue && [payload isKindOfClass:[NSDictionary class]] &&
                payload[@"url"]) {
              result = payload[@"url"];
              success = true;
            }

            dispatch_semaphore_signal(semaphore);
          }];

    [task resume];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    if (!success || !result) {
      return false;
    }

    __auto_type pasteboard = [NSPasteboard generalPasteboard];

    [pasteboard clearContents];
    return [pasteboard setString:result forType:NSPasteboardTypeString];
  }
}

void error_box(const char *content) {
  @autoreleasepool {
    [NSApplication sharedApplication];

    __auto_type alert = [[NSAlert alloc] init];
    alert.messageText = [NSString stringWithUTF8String:"Worker Error"];
    alert.informativeText = [NSString stringWithUTF8String:content];
    alert.alertStyle = NSAlertStyleCritical;

    [alert addButtonWithTitle:@"OK"];

    [alert runModal];
  }

  exit(EXIT_FAILURE);
}

void navigate_box(const char *path) {
  @autoreleasepool {
    [NSApplication sharedApplication];

    __auto_type alert = [[NSAlert alloc] init];
    alert.messageText = @"Reveal File";
    alert.informativeText = @"Would you like to reveal the file in Finder?";
    alert.alertStyle = NSAlertStyleInformational;

    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];

    __auto_type return_code = [alert runModal];
    if (return_code == NSAlertFirstButtonReturn) {
      __auto_type ns_path = [NSString stringWithUTF8String:path];
      __auto_type file = [NSURL fileURLWithPath:ns_path];

      [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ file ]];
    }
  }
}

bool dark_mode() {
  __auto_type appearance = [NSApp effectiveAppearance];
  __auto_type match = [appearance bestMatchFromAppearancesWithNames:@[
    NSAppearanceNameAqua, NSAppearanceNameDarkAqua
  ]];

  return [match isEqualToString:NSAppearanceNameDarkAqua];
}

// [--------------------------------------------------------------] //
// > Internal Functions                                           < //
// [--------------------------------------------------------------] //

static bool alloc_capture(Capture *capture, u64 width, u64 height) {
  if (!capture || width == 0 || height == 0) {
    return false;
  }

  const u64 length = pixel_length(width, height);

  void *data =
      mmap(NULL, length, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
  if (data == MAP_FAILED) {
    return false;
  }

  capture->data = data;
  capture->length = length;
  capture->width = width;
  capture->height = height;
  capture->stride = pixel_stride(width);

  return true;
}

static bool image_to_capture(CGImageRef image, Capture *out) {
  Capture capture = {0};
  if (!alloc_capture(&capture, CGImageGetWidth(image),
                     CGImageGetHeight(image))) {
    return false;
  }

  __auto_type color_space = CGColorSpaceCreateDeviceRGB();
  if (!color_space) {
    free_capture(&capture);
    return false;
  }

  __auto_type context = CGBitmapContextCreate(
      capture.data, capture.width, capture.height, 8, capture.stride,
      color_space, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

  CGColorSpaceRelease(color_space);

  if (!context) {
    free_capture(&capture);
    return false;
  }

  CGContextDrawImage(context, CGRectMake(0, 0, capture.width, capture.height),
                     image);

  CGContextRelease(context);

  *out = capture;
  return true;
}

static NSBitmapImageRep *image_to_bitmap(Image image) {
  __auto_type representation = [[NSBitmapImageRep alloc]
      initWithBitmapDataPlanes:NULL
                    pixelsWide:(NSInteger)image.width
                    pixelsHigh:(NSInteger)image.height
                 bitsPerSample:8
               samplesPerPixel:4
                      hasAlpha:YES
                      isPlanar:NO
                colorSpaceName:NSDeviceRGBColorSpace
                   bytesPerRow:(NSInteger)pixel_stride(image.width)
                  bitsPerPixel:32];

  if (representation) {
    memcpy([representation bitmapData], image.data,
           pixel_length(image.width, image.height));
  }

  return representation;
}
