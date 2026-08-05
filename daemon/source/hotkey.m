#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>

// [--------------------------------------------------------------] //
// > Global Variables                                             < //
// [--------------------------------------------------------------] //

static void (^on_hotkey_pressed)(void) = nil;

// [--------------------------------------------------------------] //
// > Function Implementations                                     < //
// [--------------------------------------------------------------] //

OSStatus screenshot_key_handler(__unused EventHandlerCallRef next_handler,
                                __unused EventRef event,
                                __unused void *user_data) {
  if (on_hotkey_pressed) {
    on_hotkey_pressed();
  }

  return noErr;
}

void register_screenshot_hotkey(void (^callback)(void)) {
  on_hotkey_pressed = [callback copy];

  EventTypeSpec event_type = {kEventClassKeyboard, kEventHotKeyPressed};

  InstallApplicationEventHandler(NewEventHandlerUPP(screenshot_key_handler), 1,
                                 &event_type, NULL, NULL);

  EventHotKeyID shot_key_id = {.signature = 'SHOT', .id = 1};
  EventHotKeyRef shot_key = NULL;

  RegisterEventHotKey(kVK_ANSI_3, cmdKey | shiftKey, shot_key_id,
                      GetApplicationEventTarget(), 0, &shot_key);
}
