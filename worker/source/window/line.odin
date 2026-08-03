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

	start, end, width, color, ready := process_line_creation(global, view)
	if ready {
		apply_line(global, start, end, width, color) or_return
	} else if global.line.dragging {
		draw_line_overlay(start, end, width, color)
	}

	return .None
}

@(private = "file", require_results)
process_line_creation :: proc(
	global: ^state.State,
	view: ^Viewer,
) -> (
	start: [2]f32,
	end: [2]f32,
	width: f32,
	color: raylib.Color,
	ready: bool,
) {
	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		global.line.dragging = true
		global.line.start = {global.frame.world.x, global.frame.world.y}
		global.line.end = global.line.start
	}

	if global.line.dragging {
		if raylib.IsMouseButtonDown(.LEFT) {
			global.line.end = {global.frame.world.x, global.frame.world.y}
		}

		start = global.line.start
		end = global.line.end
		width = global.line.width
		color = raylib.Color{global.line.color.r, global.line.color.g, global.line.color.b, 255} // Keep it fully opaque

		if raylib.IsMouseButtonReleased(.LEFT) && start != end {
			ready = true
		}
	}

	return
}

@(private = "file")
draw_line_overlay :: proc(start: [2]f32, end: [2]f32, width: f32, color: raylib.Color) {
	raylib.DrawLineEx(start, end, width, color)
}

@(private = "file", require_results)
apply_line :: proc(
	global: ^state.State,
	start: [2]f32,
	end: [2]f32,
	width: f32,
	color: raylib.Color,
) -> error.Error {
	// Leave nothing behind.
	global.process = {}
	global.line = {}
	global.tool = .None

	act := action.Line {
		texture = global.frame.current,
		start   = start,
		end     = end,
		width   = i32(width),
		color   = color,
	}

	result := action.handle_line(act) or_return

	replace_current_texture(global, result.texture)
	state.push_history(&global.history, act) or_return

	state.show_idle_message(&global.message)

	return .None
}
