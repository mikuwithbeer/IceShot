#import "tray.m"

// [--------------------------------------------------------------] //
// > Main Function                                                < //
// [--------------------------------------------------------------] //

int main(void) {
  @autoreleasepool {
    NSLog(@"IceShot Daemon v%s", VERSION);
    load_config();

    NSApplication *app = [NSApplication sharedApplication];

    AppDelegate *delegate = [[AppDelegate alloc] init];
    app.delegate = delegate;

    [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [app run];
  }

  return 0;
}
