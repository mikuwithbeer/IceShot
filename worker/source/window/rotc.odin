package window

import "../action"
import "../error"
import "../state"

@(private, require_results)
process_rotc :: proc(global: ^state.State) -> error.Error {
	global.process = {} // Reset the process state

	act := action.RotC {
		texture = global.frame.current,
	}

	result := action.handle_rotc(act) or_return

	replace_current_texture(global, result.texture)
	state.push_history(&global.history, act) or_return

	return .None
}
