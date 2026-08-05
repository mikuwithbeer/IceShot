#import "config.m"
#import "hotkey.m"

#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>

// [--------------------------------------------------------------] //
// > Class Interfaces                                             < //
// [--------------------------------------------------------------] //

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(strong) NSStatusItem *status_item;
@property(strong) NSMenuItem *capture_item;
@property(strong) NSMenuItem *launch_at_login;
@end

@interface AppDelegate ()
- (void)setup_status_bar;
- (void)take_screenshot;
- (void)menu_screenshot_action:(id)sender;
- (void)toggle_auto_launch:(id)sender;
- (void)redirect_github:(id)sender;
- (void)quit_app:(id)sender;
@end

// [--------------------------------------------------------------] //
// > Method Implementations                                       < //
// [--------------------------------------------------------------] //

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

  __auto_type tray_icon_path = [[NSBundle mainBundle] pathForResource:@"tray"
                                                               ofType:@"pdf"];

  if (tray_icon_path) {
    __auto_type icon = [[NSImage alloc] initWithContentsOfFile:tray_icon_path];
    [icon setTemplate:YES];
    [icon setSize:NSMakeSize(18.0, 18.0)];

    self.status_item.button.image = icon;
  }

  __auto_type menu = [[NSMenu alloc] init];

  self.capture_item = [menu addItemWithTitle:@"Capture Screen"
                                      action:@selector(menu_screenshot_action:)
                               keyEquivalent:@"3"];

  [menu addItem:[NSMenuItem separatorItem]];

  self.launch_at_login = [menu addItemWithTitle:@"Launch at Login"
                                         action:@selector(toggle_auto_launch:)
                                  keyEquivalent:@""];

  self.launch_at_login.state = daemon_config.auto_launch
                                   ? NSControlStateValueOn
                                   : NSControlStateValueOff;

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
  __auto_type worker_path =
      [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"IceShotWorker"];

  __auto_type task = [[NSTask alloc] init];
  task.executableURL = [NSURL fileURLWithPath:worker_path];

  NSError *error = nil;
  if (![task launchAndReturnError:&error]) {
    NSLog(@"failed to launch worker: %@", error.localizedDescription);
  }
}

- (void)toggle_auto_launch:(id)sender {
  daemon_config.auto_launch = !daemon_config.auto_launch;

  NSError *error = nil;
  if (daemon_config.auto_launch) {
    [SMAppService.mainAppService registerAndReturnError:&error];
  } else {
    [SMAppService.mainAppService unregisterAndReturnError:&error];
  }

  if (error) {
    NSLog(@"failed to change startup property: %@", error);
  }

  self.launch_at_login.state = daemon_config.auto_launch
                                   ? NSControlStateValueOn
                                   : NSControlStateValueOff;

  save_config();
}

- (void)redirect_github:(id)sender {
  __auto_type url =
      [NSURL URLWithString:@"https://github.com/mikuwithbeer/IceShot"];
  [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)quit_app:(id)sender {
  [NSApp terminate:nil];
}
@end
