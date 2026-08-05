package tools

import "../action"
import "../error"
import "../state"

import "vendor:raylib"

@(require_results)
rectangle :: proc(global: ^state.State) -> error.Error {
	if global.tool != .Rectangle {
		return .None
	}

	area, color, ready := start(global)
	if ready {
		end(global, area, color) or_return
	} else if global.rectangle.dragging {
		show(global, area, color)
	}

	return .None
}

@(private = "file", require_results)
start :: proc(global: ^state.State) -> (area: raylib.Rectangle, color: raylib.Color, ready: bool) {
	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		global.rectangle.dragging = true
		global.rectangle.start, global.rectangle.end = global.frame.world, global.frame.world
	}

	if global.rectangle.dragging {
		if raylib.IsMouseButtonDown(.LEFT) {
			global.rectangle.end = global.frame.world
		}

		area = raylib.Rectangle {
			x      = min(global.rectangle.start.x, global.rectangle.end.x),
			y      = min(global.rectangle.start.y, global.rectangle.end.y),
			width  = abs(global.rectangle.start.x - global.rectangle.end.x),
			height = abs(global.rectangle.start.y - global.rectangle.end.y),
		}

		// Keep color fully opaque.
		color = {global.rectangle.color.r, global.rectangle.color.g, global.rectangle.color.b, 255}

		if raylib.IsMouseButtonReleased(.LEFT) && area.width >= 1 && area.height >= 1 {
			ready = true
		}
	}

	return
}

@(private = "file", require_results)
end :: proc(global: ^state.State, area: raylib.Rectangle, color: raylib.Color) -> error.Error {
	act := action.Rectangle {
		texture = global.frame.current,
		area    = area,
		empty   = global.rectangle.empty,
		width   = i32(global.rectangle.width),
		color   = color,
	}

	result := action.rectangle(act) or_return
	replace_current_texture(global, result.texture)

	state.push_history(&global.history, act) or_return
	state.show_idle_message(&global.message)

	global.process, global.rectangle, global.tool = {}, {}, .None // Reset the process state
	return .None
}

@(private = "file")
show :: proc(global: ^state.State, area: raylib.Rectangle, color: raylib.Color) {
	if global.rectangle.empty {
		raylib.DrawRectangleLinesEx(area, global.rectangle.width, color)
	} else {
		raylib.DrawRectangleRec(area, color)
	}
}
