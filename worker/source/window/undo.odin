package window

import "../action"
import "../error"
import "../state"

@(private, require_results)
process_undo :: proc(global: ^state.State) -> error.Error {
	global.process = {} // Reset the process state

	state.pop_history(&global.history) or_return
	rebuild_from_history(global) or_return

	state.show_undo_message(&global.message)

	return .None
}

@(private = "file", require_results)
rebuild_from_history :: proc(global: ^state.State) -> error.Error {
	replace_current_texture(global, global.frame.initial)

	for value in global.history.actions {
		#partial switch act in value {
		case action.Crop:
			act_copy := act
			act_copy.texture = global.frame.current // The saved texture may no longer be valid

			result := action.handle_crop(act_copy) or_return
			replace_current_texture(global, result.texture)
		case action.Rect:
			act_copy := act
			act_copy.texture = global.frame.current // The saved texture may no longer be valid

			result := action.handle_rect(act_copy) or_return
			replace_current_texture(global, result.texture)
		case action.RotC:
			act_copy := act
			act_copy.texture = global.frame.current // The saved texture may no longer be valid

			result := action.handle_rotc(act_copy) or_return
			replace_current_texture(global, result.texture)
		}
	}

	return .None
}
