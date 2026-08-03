package window

import "../action"
import "../error"
import "../state"

@(private, require_results)
process_copy :: proc(global: ^state.State) -> error.Error {
	// Leave nothing behind.
	global.process = {}

	act := action.Copy {
		texture = global.frame.current,
	}

	action.handle_copy(act) or_return
	state.show_copied_message(&global.message)

	return .None
}
