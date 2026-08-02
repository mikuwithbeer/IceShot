package window

import "../action"
import "../error"
import "../state"

import "vendor:raylib"

@(private, require_results)
process_crop :: proc(global: ^state.State, view: ^Viewer) -> error.Error {
	if global.tool != .Crop {
		return .None
	}

	area, ready := process_crop_selection(global, view)
	if ready {
		result := apply_crop(global, area) or_return
		view.camera.target = {f32(result.width) * 0.5, f32(result.height) * 0.5}
	} else if global.crop.dragging {
		draw_crop_overlay(area, view.camera.zoom)
	}

	return .None
}

@(private = "file")
process_crop_selection :: proc(
	global: ^state.State,
	view: ^Viewer,
) -> (
	area: raylib.Rectangle,
	ready: bool,
) {
	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		global.crop.dragging = true
		global.crop.start = {global.frame.world.x, global.frame.world.y}
		global.crop.end = global.crop.start
	}

	if global.crop.dragging {
		if raylib.IsMouseButtonDown(.LEFT) {
			global.crop.end = {global.frame.world.x, global.frame.world.y}
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

@(private = "file")
draw_crop_overlay :: proc(area: raylib.Rectangle, zoom: f32) {
	raylib.DrawRectangleRec(area, {121, 191, 255, 55})
	raylib.DrawRectangleLinesEx(area, 2.0 / zoom, {121, 191, 255, 255})
}

@(private = "file", require_results)
apply_crop :: proc(
	global: ^state.State,
	area: raylib.Rectangle,
) -> (
	result: action.Crop_Result,
	err: error.Error,
) {
	global.process = {}
	global.crop = {}
	global.tool = .None

	act := action.Crop {
		texture = global.frame.current,
		area    = area,
	}

	result = action.handle_crop(act) or_return

	replace_current_texture(global, result.texture)
	state.push_history(&global.history, act) or_return

	state.show_idle_message(&global.message)

	return
}
