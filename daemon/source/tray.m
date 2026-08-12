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

  __weak __typeof__(self) weak_self = self;
  register_screenshot_hotkey(^{
    [weak_self take_screenshot];
  });
}

- (void)applicationWillTerminate:(NSNotification *)notification {
  unregister_screenshot_hotkey();
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
                               keyEquivalent:@""];

  [self.capture_item setTarget:self];

  [menu addItem:[NSMenuItem separatorItem]];

  self.launch_at_login = [menu addItemWithTitle:@"Launch at Login"
                                         action:@selector(toggle_auto_launch:)
                                  keyEquivalent:@""];

  [self.launch_at_login setTarget:self];

  self.launch_at_login.state = daemon_config.auto_launch
                                   ? NSControlStateValueOn
                                   : NSControlStateValueOff;

  [menu addItem:[NSMenuItem separatorItem]];

  NSMenuItem *github_item = [menu addItemWithTitle:@"GitHub"
                                            action:@selector(redirect_github:)
                                     keyEquivalent:@""];

  [github_item setTarget:self];

  NSMenuItem *about_item = [menu addItemWithTitle:@"About"
                                           action:@selector(show_about:)
                                    keyEquivalent:@""];

  [about_item setTarget:self];

  NSMenuItem *quit_item = [menu addItemWithTitle:@"Quit"
                                          action:@selector(quit_app:)
                                   keyEquivalent:@"q"];

  [quit_item setTarget:self];

  [self.status_item setMenu:menu];
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
  BOOL requested_state = !daemon_config.auto_launch;

  NSError *error = nil;
  if (!set_auto_launch(requested_state, &error)) {
    NSLog(@"failed to change startup property: %@", error);
    return;
  }

  daemon_config.auto_launch = requested_state;
  self.launch_at_login.state =
      requested_state ? NSControlStateValueOn : NSControlStateValueOff;

  if (!save_config()) {
    NSLog(@"startup property changed, but the preference could not be saved");
  }
}

- (void)redirect_github:(id)sender {
  __auto_type url =
      [NSURL URLWithString:@"https://github.com/mikuwithbeer/IceShot"];
  [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)show_about:(id)sender {
  [NSApp orderFrontStandardAboutPanel:nil];
  [NSApp activateIgnoringOtherApps:YES];
}

- (void)quit_app:(id)sender {
  [NSApp terminate:nil];
}
@end
