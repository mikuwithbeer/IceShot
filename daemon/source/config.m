#import <Foundation/Foundation.h>
#import <ServiceManagement/ServiceManagement.h>

// [--------------------------------------------------------------] //
// > Data Structures                                              < //
// [--------------------------------------------------------------] //

typedef struct {
  BOOL auto_launch;
} Config;

// [--------------------------------------------------------------] //
// > Global Variables                                             < //
// [--------------------------------------------------------------] //

Config daemon_config = {NO};
extern Config daemon_config;

static __auto_type default_config = @"{\n"
                                    @"  \"auto_launch\": false\n"
                                    @"}\n";

// [--------------------------------------------------------------] //
// > Forward Declarations                                         < //
// [--------------------------------------------------------------] //

static BOOL set_auto_launch(BOOL enabled, NSError **error);

// [--------------------------------------------------------------] //
// > Function Implementations                                     < //
// [--------------------------------------------------------------] //

BOOL load_config(void) {
  __auto_type file_manager = [NSFileManager defaultManager];
  __auto_type directory =
      [NSHomeDirectory() stringByAppendingPathComponent:@".iceshot"];
  __auto_type path = [directory stringByAppendingPathComponent:@"daemon.json"];

  [file_manager createDirectoryAtPath:directory
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];

  if (![file_manager fileExistsAtPath:path]) {
    __auto_type data = [default_config dataUsingEncoding:NSUTF8StringEncoding];
    if (![data writeToFile:path atomically:YES]) {
      NSLog(@"failed to write default config: %@", path);
      return NO;
    }
  }

  __auto_type data = [NSData dataWithContentsOfFile:path];
  if (!data) {
    NSLog(@"failed to read config: %@", path);
    return NO;
  }

  NSError *parser_error = nil;
  id json = [NSJSONSerialization JSONObjectWithData:data
                                            options:0
                                              error:&parser_error];

  if (![json isKindOfClass:[NSDictionary class]]) {
    id reason = parser_error ? parser_error
                             : @"expected the root value to be an object";
    NSLog(@"failed to parse config '%@': %@", path, reason);
    return NO;
  }

  id auto_launch = json[@"auto_launch"];
  if (![auto_launch isKindOfClass:[NSNumber class]] ||
      CFGetTypeID((__bridge CFTypeRef)auto_launch) != CFBooleanGetTypeID()) {
    NSLog(@"invalid config '%@': 'auto_launch' must be a boolean", path);
    return NO;
  }

  daemon_config.auto_launch = [auto_launch boolValue];

  NSError *service_error = nil;
  if (!set_auto_launch(daemon_config.auto_launch, &service_error)) {
    NSLog(@"failed to apply startup property: %@", service_error);
    return NO;
  }

  return YES;
}

BOOL save_config(void) {
  __auto_type file_manager = [NSFileManager defaultManager];
  __auto_type directory =
      [NSHomeDirectory() stringByAppendingPathComponent:@".iceshot"];
  __auto_type path = [directory stringByAppendingPathComponent:@"daemon.json"];

  NSError *error = nil;
  [file_manager createDirectoryAtPath:directory
          withIntermediateDirectories:YES
                           attributes:nil
                                error:&error];

  if (error) {
    NSLog(@"failed to create directory '%@': %@", directory, error);
    return NO;
  }

  id json = @{@"auto_launch" : @(daemon_config.auto_launch)};
  __auto_type data =
      [NSJSONSerialization dataWithJSONObject:json
                                      options:NSJSONWritingPrettyPrinted
                                        error:&error];

  if (!data) {
    NSLog(@"failed to serialize configuration: %@", error);
    return NO;
  }

  if (![data writeToFile:path options:NSDataWritingAtomic error:&error]) {
    NSLog(@"failed to write file '%@': %@", path, error);
    return NO;
  }

  return YES;
}

static BOOL set_auto_launch(BOOL enabled, NSError **error) {
  __auto_type service = SMAppService.mainAppService;

  if (enabled) {
    if (service.status == SMAppServiceStatusEnabled ||
        service.status == SMAppServiceStatusRequiresApproval) {
      return YES;
    }

    return [service registerAndReturnError:error];
  }

  if (service.status == SMAppServiceStatusNotRegistered) {
    return YES;
  }

  return [service unregisterAndReturnError:error];
}
