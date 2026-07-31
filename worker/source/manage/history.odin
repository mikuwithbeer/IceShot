package manage

// import "../action"
import "../error"

import "base:runtime"

import "vendor:raylib"

Manage_History :: struct {
	ready:      bool,
	shots:      [dynamic]raylib.Texture2D,
	_allocator: runtime.Allocator,
}

@(require_results)
init_history :: proc(
	allocator := context.allocator,
) -> (
	history: Manage_History,
	err: error.Error,
) {
	history._allocator = allocator

	shots, allocate_err := make(type_of(history.shots), 0, 64, allocator = allocator)
	if allocate_err != .None {
		err = .Out_Of_Memory
		return
	}

	history.ready = true
	history.shots = shots

	return
}

@(require_results)
push_history :: proc(history: ^Manage_History, texture: raylib.Texture2D) -> error.Error {
	_, allocate_err := append(&history.shots, texture)
	if allocate_err != .None {
		return .Out_Of_Memory
	}

	return .None
}

@(require_results)
pop_history :: proc(history: ^Manage_History) -> (texture: raylib.Texture2D, err: error.Error) {
	ok: bool
	texture, ok = pop_safe(&history.shots)
	if !ok {
		err = .Empty_History
	}

	return
}

free_history :: proc(history: ^Manage_History) {
	delete(history.shots)
	history.ready = false
}
