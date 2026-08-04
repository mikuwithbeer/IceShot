#import <Foundation/Foundation.h>
#import <ServiceManagement/ServiceManagement.h>

typedef struct {
  BOOL auto_launch;
} Config;

Config daemon_config = {.auto_launch = NO};

extern Config daemon_config;

static __auto_type default_config = @"{\n"
                                    @"  \"auto_launch\": false\n"
                                    @"}\n";

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

  NSError *error = nil;
  id json = [NSJSONSerialization JSONObjectWithData:data
                                            options:0
                                              error:&error];

  if (![json isKindOfClass:[NSDictionary class]]) {
    NSLog(@"expected data to be a dictionary");
    return NO;
  }

  if (daemon_config.auto_launch) {
    [SMAppService.mainAppService registerAndReturnError:&error];
  } else {
    [SMAppService.mainAppService unregisterAndReturnError:&error];
  }

  if (error) {
    NSLog(@"failed to change startup property: %@", error);
    return NO;
  }

  daemon_config.auto_launch = [json[@"auto_launch"] boolValue];

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
