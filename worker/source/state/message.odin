package state

import "core:time"

Message :: struct {
	content: cstring,
	updated: time.Time,
}

show_idle_message :: proc(message: ^Message) {
	message.content = "Waiting for an action..."
	message.updated = time.now()
}

show_select_area_message :: proc(message: ^Message) {
	message.content = "Click and drag to capture an area"
	message.updated = time.now()
}

show_create_rectangle_message :: proc(message: ^Message) {
	message.content = "Click and drag to draw a rectangle"
	message.updated = time.now()
}

show_create_line_message :: proc(message: ^Message) {
	message.content = "Click and drag to draw a line"
	message.updated = time.now()
}

show_pick_color_message :: proc(message: ^Message) {
	message.content = "Click any pixel to pick its color"
	message.updated = time.now()
}

show_measure_distance_message :: proc(message: ^Message) {
	message.content = "Click to measure dimensions"
	message.updated = time.now()
}

show_ocr_failed_message :: proc(message: ^Message) {
	message.content = "Could not spot any text!"
	message.updated = time.now()
}

show_copied_message :: proc(message: ^Message) {
	message.content = "Copied! Your clipboard is feeling useful."
	message.updated = time.now()
}

show_saved_message :: proc(message: ^Message) {
	message.content = "Saved to file. Future you says thanks!"
	message.updated = time.now()
}

show_undo_message :: proc(message: ^Message) {
	message.content = "Undone. Like it never happened!"
	message.updated = time.now()
}

show_redo_message :: proc(message: ^Message) {
	message.content = "Redone. Right back where we were!"
	message.updated = time.now()
}
