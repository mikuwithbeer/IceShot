package window

import "../action"
import "../error"
import "../state"

@(private, require_results)
process_save :: proc(global: ^state.State, allocator := context.allocator) -> error.Error {
	global.process = {} // Reset the process state

	act := action.Save {
		texture = global.frame.current,
	}

	result := action.handle_save(act, allocator) or_return
	action.free_action_result(result, allocator)

	state.show_saved_message(&global.message)

	return .None
}
