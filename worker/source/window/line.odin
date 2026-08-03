package window

import "../action"
import "../error"
import "../state"

import "vendor:raylib"

@(private, require_results)
process_line :: proc(global: ^state.State, view: ^Viewer) -> error.Error {
	if global.tool != .Line {
		return .None
	}

	color, ready := process_line_creation(global, view)
	if ready {
		apply_line(global, color) or_return
	} else if global.line.dragging {
		draw_line_overlay(global, color)
	}

	return .None
}

@(private = "file", require_results)
process_line_creation :: proc(
	global: ^state.State,
	view: ^Viewer,
) -> (
	color: raylib.Color,
	ready: bool,
) {
	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		global.line.dragging = true
		global.line.start = global.frame.world
		global.line.end = global.frame.world
	}

	if global.line.dragging {
		if raylib.IsMouseButtonDown(.LEFT) {
			global.line.end = global.frame.world
		}

		color = {global.line.color.r, global.line.color.g, global.line.color.b, 255} // Keep it fully opaque

		if raylib.IsMouseButtonReleased(.LEFT) && global.line.start != global.line.end {
			ready = true
		}
	}

	return
}

@(private = "file")
draw_line_overlay :: proc(global: ^state.State, color: raylib.Color) {
	raylib.DrawLineEx(global.line.start, global.line.end, global.line.width, color)
}

@(private = "file", require_results)
apply_line :: proc(global: ^state.State, color: raylib.Color) -> error.Error {
	act := action.Line {
		texture = global.frame.current,
		start   = global.line.start,
		end     = global.line.end,
		width   = i32(global.line.width),
		color   = color,
	}

	result := action.handle_line(act) or_return

	replace_current_texture(global, result.texture)
	state.push_history(&global.history, act) or_return

	state.show_idle_message(&global.message)

	global.process, global.line, global.tool = {}, {}, .None // Reset the process state

	return .None
}
