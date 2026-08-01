package window

import "../action"
import "../error"
import "../state"

@(private, require_results)
process_read :: proc(global: ^state.State) -> error.Error {
	global.process = {}

	act := action.Read {
		texture = global.frame.current,
	}

	action.handle_read(act) or_return
	return .None
}
