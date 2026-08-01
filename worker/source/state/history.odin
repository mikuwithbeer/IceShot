package state

import "../action"
import "../error"

import "base:runtime"

History :: struct {
	running:    bool,
	actions:    [dynamic]action.Action,
	_allocator: runtime.Allocator,
}

@(require_results)
init_history :: proc(allocator := context.allocator) -> (history: History, err: error.Error) {
	history._allocator = allocator

	actions, allocate_err := make(type_of(history.actions), 0, 64, allocator = allocator)
	if allocate_err != .None {
		err = .Out_Of_Memory
		return
	}

	history.running = true
	history.actions = actions

	return
}

@(require_results)
push_history :: proc(history: ^History, act: action.Action) -> error.Error {
	_, allocate_err := append(&history.actions, act)
	if allocate_err != .None {
		return .Out_Of_Memory
	}

	return .None
}

@(require_results)
pop_history :: proc(history: ^History) -> error.Error {
	_, ok := pop_safe(&history.actions)
	if !ok {
		return .Empty_History
	}

	return .None
}

free_history :: proc(history: ^History) {
	history.running = false
	delete(history.actions)
}
