#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(strong) NSStatusItem *status_item;
@end

@interface AppDelegate ()
- (void)screenshot:(id)sender;
- (void)quit:(id)sender;
@end

OSStatus screenshot_key_handler(EventHandlerCallRef _next, EventRef event,
                                void *data) {
  AppDelegate *delegate = (__bridge AppDelegate *)data;
  [delegate screenshot:nil];

  return noErr;
}

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
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

  NSMenuItem *item = [menu addItemWithTitle:@"Capture Screen"
                                     action:@selector(screenshot:)
                              keyEquivalent:@"3"];

  [item setKeyEquivalentModifierMask:NSEventModifierFlagCommand |
                                     NSEventModifierFlagShift];

  [menu addItem:[NSMenuItem separatorItem]];

  [menu addItemWithTitle:@"Quit" action:@selector(quit:) keyEquivalent:@"q"];

  self.status_item.menu = menu;

  EventTypeSpec event_type = {kEventClassKeyboard, kEventHotKeyPressed};

  InstallApplicationEventHandler(NewEventHandlerUPP(screenshot_key_handler), 1,
                                 &event_type, (__bridge void *)self, NULL);

  EventHotKeyID shot_key_id = {.signature = 'SHOT', .id = 1};

  EventHotKeyRef shot_key = NULL;
  RegisterEventHotKey(kVK_ANSI_3, cmdKey | shiftKey, shot_key_id,
                      GetApplicationEventTarget(), 0, &shot_key);
}

- (void)screenshot:(id)sender {
  NSString *worker_path =
      [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"IceShotWorker"];

  NSTask *task = [[NSTask alloc] init];
  task.executableURL = [NSURL fileURLWithPath:worker_path];

  NSError *error = nil;
  if (![task launchAndReturnError:&error]) {
    NSLog(@"failed to launch worker: %@", error.localizedDescription);
  }
}

- (void)quit:(id)sender {
  [NSApp terminate:nil];
}
@end
