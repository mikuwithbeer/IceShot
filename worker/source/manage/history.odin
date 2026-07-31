package manage

import "base:runtime"

import "vendor:raylib"

Manage_History :: struct {
	ready:      bool,
	shots:      [dynamic]raylib.Texture2D,
	_allocator: runtime.Allocator,
}

@(require_results)
init_history :: proc(allocator := context.allocator) -> (history: Manage_History, ok: bool) {
	history._allocator = allocator

	shots, err := make(type_of(history.shots), 0, 64, allocator = allocator)
	if err != .None {
		return
	}

	history.ready = true
	history.shots = shots

	ok = true
	return
}

@(require_results)
push_history :: proc(history: ^Manage_History, texture: raylib.Texture2D) -> (ok: bool) {
	_, err := append(&history.shots, texture)
	if err != .None {
		return
	}

	ok = true
	return
}

@(require_results)
pop_history :: proc(history: ^Manage_History) -> (texture: raylib.Texture2D, ok: bool) {
	texture = pop_safe(&history.shots) or_return

	ok = true
	return
}

free_history :: proc(history: ^Manage_History) {
	delete(history.shots)
	history.ready = false
}
