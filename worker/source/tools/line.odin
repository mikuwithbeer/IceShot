package tools

import "../action"
import "../error"
import "../state"

import "vendor:raylib"

@(require_results)
line :: proc(global: ^state.State) -> error.Error {
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

@(private = "file", require_results)
start :: proc(global: ^state.State) -> (color: raylib.Color, ready: bool) {
	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		global.line.dragging = true
		global.line.start = global.frame.world
		global.line.end = global.frame.world
	}

	if global.line.dragging {
		if raylib.IsMouseButtonDown(.LEFT) {
			global.line.end = global.frame.world
		}

		// Keep the color fully opaque.
		color = {global.line.color.r, global.line.color.g, global.line.color.b, 255}

		if raylib.IsMouseButtonReleased(.LEFT) && global.line.start != global.line.end {
			ready = true
		}
	}

	return
}

@(private = "file", require_results)
end :: proc(global: ^state.State, color: raylib.Color) -> error.Error {
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

	global.process, global.line, global.tool = {}, {}, .None
	return .None
}

@(private = "file")
show :: proc(global: ^state.State, color: raylib.Color) {
	raylib.DrawLineEx(global.line.start, global.line.end, global.line.width, color)
}
