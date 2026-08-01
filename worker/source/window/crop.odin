package window

import "../action"
import "../error"
import "../state"

import "vendor:raylib"

@(private, require_results)
process_crop :: proc(global: ^state.State, view: ^Viewer) -> (err: error.Error) {
	if global.tool != .Crop {
		return
	}

	area, ready := process_crop_selection(global, view)
	if ready {
		apply_crop(global, area) or_return
	} else if global.crop.dragging {
		draw_crop_overlay(area, view.camera.zoom)
	}

	return
}

@(private = "file")
process_crop_selection :: proc(
	global: ^state.State,
	view: ^Viewer,
) -> (
	area: raylib.Rectangle,
	ready: bool,
) {
	absolute := raylib.Vector2 {
		global.frame.cursor.x * global.frame.dpi.x,
		global.frame.cursor.y * global.frame.dpi.y,
	}

	world := raylib.GetScreenToWorld2D(absolute, view.camera)
	world.x = raylib.Clamp(world.x, 0.0, f32(global.frame.current.width))
	world.y = raylib.Clamp(world.y, 0.0, f32(global.frame.current.height))

	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		global.crop.dragging = true
		global.crop.start = {world.x, world.y}
		global.crop.end = {world.x, world.y}
	}

	if global.crop.dragging {
		if raylib.IsMouseButtonDown(.LEFT) {
			global.crop.end = {world.x, world.y}
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
	raylib.DrawRectangleRec(area, {121, 191, 255, 80})
	raylib.DrawRectangleLinesEx(area, 2.0 / zoom, {121, 191, 255, 255})
}

@(private = "file", require_results)
apply_crop :: proc(global: ^state.State, area: raylib.Rectangle) -> (err: error.Error) {
	global.tool = .None
	global.crop.dragging = false

	act := action.Crop {
		texture = global.frame.current,
		area    = area,
	}

	result := action.handle_crop(act) or_return

	replace_current_texture(global, result.texture)
	state.push_history(&global.history, act) or_return

	return
}
