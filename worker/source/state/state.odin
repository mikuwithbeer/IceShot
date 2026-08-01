package state

import "../error"

State :: struct {
	crop:    Crop,
	frame:   Frame,
	history: History,
}

@(require_results)
init_state :: proc(allocator := context.allocator) -> (state: State, err: error.Error) {
	state.history = init_history(allocator = allocator) or_return
	return
}

free_state :: proc(state: ^State) {
	free_history(&state.history)
}
