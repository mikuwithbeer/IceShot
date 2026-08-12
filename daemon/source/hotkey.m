#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>

// [--------------------------------------------------------------] //
// > Global Variables                                             < //
// [--------------------------------------------------------------] //

static void (^hotkey_callback)(void);

static EventHandlerRef event_handler;
static EventHandlerUPP event_handler_upp;
static EventHotKeyRef hotkey;

// [--------------------------------------------------------------] //
// > Forward Declarations                                         < //
// [--------------------------------------------------------------] //

void unregister_screenshot_hotkey(void);

// [--------------------------------------------------------------] //
// > Function Implementations                                     < //
// [--------------------------------------------------------------] //

OSStatus handle_hotkey(__unused EventHandlerCallRef next_handler,
                       __unused EventRef event, __unused void *user_data) {
  if (hotkey_callback) {
    hotkey_callback();
  }

  return noErr;
}

BOOL register_screenshot_hotkey(void (^callback)(void)) {
  if (hotkey) {
    return YES;
  }

  hotkey_callback = [callback copy];

  EventTypeSpec event_type = {kEventClassKeyboard, kEventHotKeyPressed};
  event_handler_upp = NewEventHandlerUPP(handle_hotkey);

  __auto_type status = InstallApplicationEventHandler(
      event_handler_upp, 1, &event_type, NULL, &event_handler);

  if (status != noErr) {
    NSLog(@"failed to install hotkey handler: %d", (int)status);
    unregister_screenshot_hotkey();
    return NO;
  }

  EventHotKeyID identifier = {.signature = 'SHOT', .id = 1};

  status = RegisterEventHotKey(kVK_ANSI_3, cmdKey | shiftKey, identifier,
                               GetApplicationEventTarget(), 0, &hotkey);

  if (status != noErr) {
    NSLog(@"failed to register screenshot key: %d", (int)status);
    unregister_screenshot_hotkey();
    return NO;
  }

  return YES;
}

void unregister_screenshot_hotkey(void) {
  if (hotkey) {
    UnregisterEventHotKey(hotkey);
    hotkey = NULL;
  }

  if (event_handler) {
    RemoveEventHandler(event_handler);
    event_handler = NULL;
  }

  if (event_handler_upp) {
    DisposeEventHandlerUPP(event_handler_upp);
    event_handler_upp = NULL;
  }

  hotkey_callback = nil;
}
