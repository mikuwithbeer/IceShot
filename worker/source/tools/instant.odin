package tools

import "../action"
import "../error"
import "../state"

@(require_results)
make_rotate :: proc(global: ^state.State) -> error.Error {
	act := action.Rotate{global.frame.current}

	result := action.rotate(act) or_return
	replace_current_texture(global, result.texture)

	state.push_history(&global.history, act) or_return
	free_rotate(global)

	return .None
}

@(require_results)
make_undo :: proc(global: ^state.State) -> error.Error {
	state.undo_history(&global.history) or_return
	rebuild_from_history(global) or_return

	state.show_undo_message(&global.message)
	free_undo(global)

	return .None
}

@(require_results)
make_redo :: proc(global: ^state.State) -> error.Error {
	state.redo_history(&global.history) or_return
	rebuild_from_history(global) or_return

	state.show_redo_message(&global.message)
	free_redo(global)

	return .None
}

@(require_results)
make_share :: proc(global: ^state.State) -> (err: error.Error) {
	if imgbb, ok := global.config.upload.imgbb.?; ok {
		act := action.Share {
			texture = global.frame.current,
			token   = imgbb,
		}

		err = action.share(act)
		if err == .Failed_To_Upload {
			state.show_upload_failed_message(&global.message)
			err = .None
		} else {
			state.show_copied_message(&global.message)
		}
	} else {
		state.show_unknown_token_message(&global.message)
	}

	free_share(global)
	return err
}

@(require_results)
make_copy :: proc(global: ^state.State) -> error.Error {
	act := action.Copy {
		texture = global.frame.current,
	}

	action.copy(act) or_return
	state.show_copied_message(&global.message)

	free_copy(global)
	return .None
}

@(require_results)
make_save :: proc(global: ^state.State, allocator := context.allocator) -> error.Error {
	act := action.Save {
		texture = global.frame.current,
		home    = state.get_home_path(&global.config),
		path    = global.config.save.path,
		format  = global.config.save.format,
		reveal  = global.config.save.reveal,
	}

	action.save(act, allocator) or_return
	state.show_saved_message(&global.message)

	free_save(global)
	return .None
}

@(private = "file")
free_rotate :: proc(global: ^state.State) {
	global.process.rotate = false
}

@(private = "file")
free_undo :: proc(global: ^state.State) {
	global.process.undo = false
}

@(private = "file")
free_redo :: proc(global: ^state.State) {
	global.process.redo = false
}

@(private = "file")
free_share :: proc(global: ^state.State) {
	global.process.share = false
}

@(private = "file")
free_copy :: proc(global: ^state.State) {
	global.process.copy = false
}

@(private = "file")
free_save :: proc(global: ^state.State) {
	global.process.save = false
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
