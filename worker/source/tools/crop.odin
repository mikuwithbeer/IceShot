package tools

import "../action"
import "../error"
import "../state"

import "vendor:raylib"

@(require_results)
crop :: proc(global: ^state.State, color_first, color_second: raylib.Color) -> error.Error {
	if global.tool != .Crop {
		return .None
	}

	area, ready := start(global)
	if ready {
		result := end(global, area) or_return

		// Keep the image stays in focus.
		global.frame.camera.target = {f32(result.width) * 0.5, f32(result.height) * 0.5}
	} else if global.crop.dragging {
		show(global, area, color_first, color_second)
	}

	return .None
}

@(private = "file", require_results)
start :: proc(global: ^state.State) -> (area: raylib.Rectangle, ready: bool) {
	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		global.crop.dragging = true
		global.crop.start = global.frame.world
		global.crop.end = global.frame.world
	}

	if global.crop.dragging {
		if raylib.IsMouseButtonDown(.LEFT) {
			global.crop.end = global.frame.world
		}

		area = raylib.Rectangle {
			x      = min(global.crop.start.x, global.crop.end.x),
			y      = min(global.crop.start.y, global.crop.end.y),
			width  = abs(global.crop.start.x - global.crop.end.x),
			height = abs(global.crop.start.y - global.crop.end.y),
		}

		if raylib.IsMouseButtonReleased(.LEFT) && area.width >= 1 && area.height >= 1 {
			ready = true
		}
	}

	return
}

@(private = "file", require_results)
end :: proc(
	global: ^state.State,
	area: raylib.Rectangle,
) -> (
	result: action.Result,
	err: error.Error,
) {
	act := action.Crop {
		texture = global.frame.current,
		area    = area,
	}

	result = action.crop(act) or_return
	replace_current_texture(global, result.texture)

	state.push_history(&global.history, act) or_return
	state.show_idle_message(&global.message)

	global.process, global.crop, global.tool = {}, {}, .None // Reset the process state
	return
}

@(private = "file")
show :: proc(
	global: ^state.State,
	area: raylib.Rectangle,
	color_first, color_second: raylib.Color,
) {
	raylib.DrawRectangleRec(area, color_second)
	raylib.DrawRectangleLinesEx(area, 2.0 / global.frame.camera.zoom, color_first)
}
