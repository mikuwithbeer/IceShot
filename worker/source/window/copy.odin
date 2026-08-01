package window

import "../action"
import "../error"
import "../state"

@(private, require_results)
process_copy :: proc(global: ^state.State) -> error.Error {
	global.process = {}

	act := action.Copy {
		texture = global.frame.current,
	}

	action.handle_copy(act) or_return
	return .None
}
