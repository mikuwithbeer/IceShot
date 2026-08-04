#import "hotkey.m"

#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(strong) NSStatusItem *status_item;
@end

@interface AppDelegate ()
- (void)setup_status_bar;
- (void)take_screenshot;
- (void)menu_screenshot_action:(id)sender;
- (void)redirect_github:(id)sender;
- (void)quit_app:(id)sender;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  [self setup_status_bar];

  __block __typeof__(self) block_self = self;
  register_screenshot_hotkey(^{
    [block_self take_screenshot];
  });
}

- (void)setup_status_bar {
  self.status_item = [[NSStatusBar systemStatusBar]
      statusItemWithLength:NSVariableStatusItemLength];

  NSString *tray_icon_path = [[NSBundle mainBundle] pathForResource:@"tray"
                                                             ofType:@"pdf"];

  if (tray_icon_path) {
    NSImage *icon = [[NSImage alloc] initWithContentsOfFile:tray_icon_path];
    [icon setTemplate:YES];
    [icon setSize:NSMakeSize(18.0, 18.0)];

    self.status_item.button.image = icon;
  }

  NSMenu *menu = [[NSMenu alloc] init];

  NSMenuItem *capture_item =
      [menu addItemWithTitle:@"Capture Screen"
                      action:@selector(menu_screenshot_action:)
               keyEquivalent:@"3"];

  [capture_item setKeyEquivalentModifierMask:NSEventModifierFlagCommand |
                                             NSEventModifierFlagShift];

  [menu addItem:[NSMenuItem separatorItem]];

  [menu addItemWithTitle:@"Source Code"
                  action:@selector(redirect_github:)
           keyEquivalent:@""];

  [menu addItemWithTitle:@"Quit"
                  action:@selector(quit_app:)
           keyEquivalent:@"q"];

  self.status_item.menu = menu;
}

- (void)menu_screenshot_action:(id)sender {
  [self take_screenshot];
}

- (void)take_screenshot {
  NSString *worker_path =
      [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"IceShotWorker"];

  NSTask *task = [[NSTask alloc] init];
  task.executableURL = [NSURL fileURLWithPath:worker_path];

  NSError *error = nil;
  if (![task launchAndReturnError:&error]) {
    NSLog(@"failed to launch worker: %@", error.localizedDescription);
  }
}

- (void)redirect_github:(id)sender {
  NSURL *url = [NSURL URLWithString:@"https://github.com/mikuwithbeer/IceShot"];
  [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)quit_app:(id)sender {
  [NSApp terminate:nil];
}
@end
