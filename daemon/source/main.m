#import "tray.m"

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    NSApplication *app = [NSApplication sharedApplication];

    AppDelegate *delegate = [[AppDelegate alloc] init];
    app.delegate = delegate;

    [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [app run];
  }
}
