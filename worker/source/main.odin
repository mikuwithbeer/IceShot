package main

import "window"

main :: proc() {
	gui, _ := window.init_window()
	defer window.free_window(&gui)

	window.load_window(&gui)
}
