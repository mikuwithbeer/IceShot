package tools

import "../action"
import "../error"
import "../state"

@(require_results)
rotate :: proc(global: ^state.State) -> error.Error {
	global.process = {}

	act := action.Rotate{global.frame.current}

	result := action.rotate(act) or_return
	replace_current_texture(global, result.texture)

	state.push_history(&global.history, act) or_return
	return .None
}

@(require_results)
undo :: proc(global: ^state.State) -> error.Error {
	global.process = {}

	state.undo_history(&global.history) or_return
	rebuild_from_history(global) or_return

	state.show_undo_message(&global.message)
	return .None
}

@(require_results)
redo :: proc(global: ^state.State) -> error.Error {
	global.process = {}

	state.redo_history(&global.history) or_return
	rebuild_from_history(global) or_return

	state.show_redo_message(&global.message)
	return .None
}

@(require_results)
read :: proc(global: ^state.State) -> error.Error {
	global.process = {}

	act := action.Read{global.frame.current}

	err := action.read(act)
	if err == .No_Text_Found {
		state.show_ocr_failed_message(&global.message)

		// Not found is expected sometimes, keep things moving.
		return .None
	} else if err == .None {
		state.show_copied_message(&global.message)
	}

	return err
}

@(require_results)
copy :: proc(global: ^state.State) -> error.Error {
	global.process = {}

	act := action.Copy {
		texture = global.frame.current,
	}

	action.copy(act) or_return
	state.show_copied_message(&global.message)

	return .None
}

@(require_results)
save :: proc(global: ^state.State, allocator := context.allocator) -> error.Error {
	global.process = {}

	act := action.Save {
		texture = global.frame.current,
		home    = state.home_config(&global.config),
		path    = global.config.save_path,
	}

	action.save(act, allocator) or_return
	state.show_saved_message(&global.message)

	return .None
}

@(private = "file", require_results)
rebuild_from_history :: proc(global: ^state.State) -> error.Error {
	replace_current_texture(global, global.frame.initial)

	for value in state.load_history(&global.history) {
		#partial switch act in value {
		case action.Crop:
			act_copy := act
			act_copy.texture = global.frame.current // The saved texture may no longer be valid

			result := action.crop(act_copy) or_return
			replace_current_texture(global, result.texture)
		case action.Rectangle:
			act_copy := act
			act_copy.texture = global.frame.current // The saved texture may no longer be valid

			result := action.rectangle(act_copy) or_return
			replace_current_texture(global, result.texture)
		case action.Line:
			act_copy := act
			act_copy.texture = global.frame.current // The saved texture may no longer be valid

			result := action.line(act_copy) or_return
			replace_current_texture(global, result.texture)
		case action.Triangle:
			act_copy := act
			act_copy.texture = global.frame.current // The saved texture may no longer be valid

			result := action.triangle(act_copy) or_return
			replace_current_texture(global, result.texture)
		case action.Rotate:
			act_copy := act
			act_copy.texture = global.frame.current // The saved texture may no longer be valid

			result := action.rotate(act_copy) or_return
			replace_current_texture(global, result.texture)
		}
	}

	return .None
}
