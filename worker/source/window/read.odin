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

	err := action.handle_read(act)
	if err == .No_Text_Found {
		state.show_ocr_failed_message(&global.message)
		return .None
	} else if err == .None {
		state.show_copied_message(&global.message)
		return .None
	} else {
		return err
	}
}
