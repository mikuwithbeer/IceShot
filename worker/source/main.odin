package main

import "error"
import "window"

import "base:runtime"

main :: proc() {
	allocator := runtime.heap_allocator()

	gui, err := window.init_window(allocator = allocator)
	if err != .None {
		window.free_window(&gui)
		error.message_box(err)
	}

	err = window.load_window(&gui)
	window.free_window(&gui)

	if err != .None {
		error.message_box(err)
	}
}
