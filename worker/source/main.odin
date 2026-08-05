package main

import "error"
import "native"
import "window"

import "base:runtime"

main :: proc() {
	allocator := runtime.heap_allocator()
	if capture, ok := capture_screenshot(); ok {
		gui, err := window.init_window(&capture, allocator = allocator)
		if err != .None {
			window.free_window(&gui)
			error.message_box(err)
		} else {
			err = window.load_window(&gui)
			window.free_window(&gui)
			error.message_box(err)
		}
	} else {
		error.message_box(.Not_Permitted)
	}
}

@(private, require_results)
capture_screenshot :: proc() -> (capture: native.Unsafe_Capture, ok: bool) {
	native.unsafe_init_capture() or_return

	size: native.Unsafe_Point2D
	native.unsafe_size_capture(&size) or_return
	native.unsafe_load_capture({0, 0}, size, &capture) or_return

	ok = true
	return
}
