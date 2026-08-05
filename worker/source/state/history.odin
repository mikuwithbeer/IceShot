package state

import "../action"
import "../error"

History :: struct {
	actions: [dynamic]action.Action,
	current: int,
	running: bool,
}

@(private, require_results)
init_history :: proc(allocator := context.allocator) -> (history: History, err: error.Error) {
	DEFAULT_CAPACITY :: 16

	actions, allocate_err := make(
		type_of(history.actions),
		0,
		DEFAULT_CAPACITY,
		allocator = allocator,
	)

	if allocate_err != .None {
		err = .Out_Of_Memory
	} else {
		history.actions = actions
		history.current = 0
		history.running = true
	}

	return
}

@(require_results)
load_history :: proc(history: ^History) -> []action.Action {
	return history.actions[:history.current]
}

@(require_results)
push_history :: proc(history: ^History, act: action.Action) -> error.Error {
	for len(history.actions) > history.current {
		pop(&history.actions)
	}

	_, allocate_err := append(&history.actions, act)
	if allocate_err != .None {
		return .Out_Of_Memory
	}

	history.current += 1
	return .None
}

@(require_results)
undo_history :: proc(history: ^History) -> error.Error {
	if history.current == 0 {
		return .Nothing_To_Undo
	}

	history.current -= 1
	return .None
}

@(require_results)
redo_history :: proc(history: ^History) -> error.Error {
	if history.current == len(history.actions) {
		return .Nothing_To_Redo
	}

	history.current += 1
	return .None
}

@(require_results)
can_undo_history :: proc(history: ^History) -> bool {
	return history.current != 0
}

@(require_results)
can_redo_history :: proc(history: ^History) -> bool {
	return history.current != len(history.actions)
}

@(private)
free_history :: proc(history: ^History) {
	history.running = false
	delete(history.actions)
}
