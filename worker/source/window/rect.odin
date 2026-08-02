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

	area, empty, color, ready := process_rect_creation(global, view)
	if ready {
		apply_rect(global, area, empty, color) or_return
	} else if global.rect.dragging {
		draw_rect_overlay(area, empty, color, view.camera.zoom)
	}

	return .None
}

@(private = "file")
process_rect_creation :: proc(
	global: ^state.State,
	view: ^Viewer,
) -> (
	area: raylib.Rectangle,
	empty: bool,
	color: raylib.Color,
	ready: bool,
) {
	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		global.rect.dragging = true
		global.rect.start = {global.frame.world.x, global.frame.world.y}
		global.rect.end = global.rect.start
	}

	if global.rect.dragging {
		if raylib.IsMouseButtonDown(.LEFT) {
			global.rect.end = {global.frame.world.x, global.frame.world.y}
		}

		area = raylib.Rectangle {
			x      = min(global.rect.start.x, global.rect.end.x),
			y      = min(global.rect.start.y, global.rect.end.y),
			width  = abs(global.rect.start.x - global.rect.end.x),
			height = abs(global.rect.start.y - global.rect.end.y),
		}

		empty = global.rect.empty
		color = raylib.Color{global.rect.color.r, global.rect.color.g, global.rect.color.b, 255}

		if raylib.IsMouseButtonReleased(.LEFT) && area.width >= 1 && area.height >= 1 {
			ready = true
		}
	}

	return
}

@(private = "file")
draw_rect_overlay :: proc(area: raylib.Rectangle, empty: bool, color: raylib.Color, zoom: f32) {
	if empty {
		raylib.DrawRectangleLinesEx(area, 2, color)
	} else {
		raylib.DrawRectangleRec(area, color)
	}
}

@(private = "file", require_results)
apply_rect :: proc(
	global: ^state.State,
	area: raylib.Rectangle,
	empty: bool,
	color: raylib.Color,
) -> error.Error {
	global.process = {}
	global.rect = {}
	global.tool = .None

	act := action.Rect {
		texture = global.frame.current,
		area    = area,
		empty   = empty,
		color   = color,
	}

	result := action.handle_rect(act) or_return

	replace_current_texture(global, result.texture)
	state.push_history(&global.history, act) or_return

	state.show_idle_message(&global.message)

	return .None
}
