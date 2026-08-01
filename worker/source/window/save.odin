package window

import "../action"
import "../error"
import "../state"

@(private, require_results)
process_save :: proc(global: ^state.State, allocator := context.allocator) -> (err: error.Error) {
	act := action.Save {
		texture = global.frame.current,
	}

	result := action.handle_save(act, allocator) or_return
	action.free_action_result(result, allocator)

	return
}
