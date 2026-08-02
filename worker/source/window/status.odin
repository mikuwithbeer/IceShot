package window

import "../state"

import "core:fmt"
import "core:time"

set_status_message :: proc(
	global: ^state.State,
	message: string,
	seconds: f64 = 2.0,
	allocator := context.allocator,
) {
	if global.frame.status_message != "" {
		delete(global.frame.status_message, allocator = allocator)
	}

	global.frame.status_message = fmt.aprintf("%s", message, allocator = allocator)
	global.frame.status_until = time.add_duration(time.now(), time.duration_from_seconds(seconds))
}

update_status_message :: proc(global: ^state.State, allocator := context.allocator) {
	if global.frame.status_message == "" {
		return
	}

	if time.compare(time.now(), global.frame.status_until) != .Less {
		delete(global.frame.status_message, allocator = allocator)
		global.frame.status_message = ""
	}
}

free_status_message :: proc(global: ^state.State, allocator := context.allocator) {
	if global.frame.status_message != "" {
		delete(global.frame.status_message, allocator = allocator)
		global.frame.status_message = ""
	}
}
