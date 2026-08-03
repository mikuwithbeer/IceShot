package window

import "../action"
import "../error"
import "../state"

import "vendor:raylib"

@(private, require_results)
process_rect :: proc(global: ^state.State, view: ^Viewer) -> error.Error {
	if global.tool != .Rect {
		return .None
	}

	area, color, ready := process_rect_creation(global, view)
	if ready {
		apply_rect(global, area, color) or_return
	} else if global.rect.dragging {
		draw_rect_overlay(global, area, color)
	}

	return .None
}

@(private = "file", require_results)
process_rect_creation :: proc(
	global: ^state.State,
	view: ^Viewer,
) -> (
	area: raylib.Rectangle,
	color: raylib.Color,
	ready: bool,
) {
	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		global.rect.dragging = true
		global.rect.start, global.rect.end = global.frame.world, global.frame.world
	}

	if global.rect.dragging {
		if raylib.IsMouseButtonDown(.LEFT) {
			global.rect.end = global.frame.world
		}

		area = raylib.Rectangle {
			x      = min(global.rect.start.x, global.rect.end.x),
			y      = min(global.rect.start.y, global.rect.end.y),
			width  = abs(global.rect.start.x - global.rect.end.x),
			height = abs(global.rect.start.y - global.rect.end.y),
		}

		color = {global.rect.color.r, global.rect.color.g, global.rect.color.b, 255} // Keep it fully opaque

		if raylib.IsMouseButtonReleased(.LEFT) && area.width >= 1 && area.height >= 1 {
			ready = true
		}
	}

	return
}

@(private = "file")
draw_rect_overlay :: proc(global: ^state.State, area: raylib.Rectangle, color: raylib.Color) {
	if global.rect.empty {
		raylib.DrawRectangleLinesEx(area, global.rect.width, color)
	} else {
		raylib.DrawRectangleRec(area, color)
	}
}

@(private = "file", require_results)
apply_rect :: proc(
	global: ^state.State,
	area: raylib.Rectangle,
	color: raylib.Color,
) -> error.Error {
	act := action.Rect {
		texture = global.frame.current,
		area    = area,
		empty   = global.rect.empty,
		width   = i32(global.rect.width),
		color   = color,
	}

	result := action.handle_rect(act) or_return

	replace_current_texture(global, result.texture)
	state.push_history(&global.history, act) or_return

	state.show_idle_message(&global.message)

	global.process, global.rect, global.tool = {}, {}, .None // Reset the process state

	return .None
}
