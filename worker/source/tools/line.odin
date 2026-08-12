package tools

import "../action"
import "../error"
import "../raylib"
import "../state"

@(require_results)
make_line :: proc(global: ^state.State) -> error.Error {
	if global.tool != .Line {
		return .None
	}

	color, ready := start(global)
	if ready {
		end(global, color) or_return
	} else if global.line.dragging {
		show(global, color)
	}

	return .None
}

free_line :: proc(global: ^state.State) {
	global.line = {}

	global.tool = .None
	global.process.line = false
}

@(private = "file", require_results)
start :: proc(global: ^state.State) -> (color: raylib.Color, ready: bool) {
	if global.frame.fly && raylib.IsMouseButtonPressed(.Left) {
		global.line.dragging = true
		global.line.start = global.frame.world
		global.line.end = global.frame.world
	}

	if global.line.dragging {
		if raylib.IsMouseButtonDown(.Left) {
			global.line.end = global.frame.world
		}

		// Keep the color fully opaque.
		color = {global.line.color.r, global.line.color.g, global.line.color.b, 255}

		if raylib.IsMouseButtonReleased(.Left) && global.line.start != global.line.end {
			ready = true
		}
	}

	return
}

@(private = "file", require_results)
end :: proc(global: ^state.State, color: raylib.Color) -> error.Error {
	defer free_line(global)

	act := action.Line {
		texture = global.frame.current,
		start   = global.line.start,
		end     = global.line.end,
		width   = i32(global.line.width),
		color   = color,
	}

	result := action.line(act) or_return
	replace_current_texture(global, result.texture)

	state.push_history(&global.history, act) or_return
	state.show_idle_message(&global.message)

	return .None
}

@(private = "file")
show :: proc(global: ^state.State, color: raylib.Color) {
	raylib.DrawLineEx(global.line.start, global.line.end, global.line.width, color)
}
