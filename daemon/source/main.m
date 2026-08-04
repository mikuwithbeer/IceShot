#import "tray.m"

int main(void) {
  @autoreleasepool {
    load_config();

    NSApplication *app = [NSApplication sharedApplication];

    AppDelegate *delegate = [[AppDelegate alloc] init];
    app.delegate = delegate;

    [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [app run];
  }

  return 0;
}
