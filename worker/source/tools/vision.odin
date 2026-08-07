package tools

import "../action"
import "../error"
import "../raylib"
import "../state"

@(require_results)
vision :: proc(global: ^state.State, color_first, color_second: raylib.Color) -> error.Error {
	if global.tool != .Vision {
		return .None
	}

	area, ready := start(global)
	if ready {
		end(global, area) or_return
	} else if global.vision.dragging {
		show(global, area, color_first, color_second)
	}

	return .None
}

@(private = "file", require_results)
start :: proc(global: ^state.State) -> (area: raylib.Rectangle, ready: bool) {
	if global.frame.fly && raylib.IsMouseButtonPressed(.Left) {
		global.vision.dragging = true
		global.vision.start = global.frame.world
		global.vision.end = global.frame.world
	}

	if global.vision.dragging {
		if raylib.IsMouseButtonDown(.Left) {
			global.vision.end = global.frame.world
		}

		area = raylib.Rectangle {
			x      = min(global.vision.start.x, global.vision.end.x),
			y      = min(global.vision.start.y, global.vision.end.y),
			width  = abs(global.vision.start.x - global.vision.end.x),
			height = abs(global.vision.start.y - global.vision.end.y),
		}

		if raylib.IsMouseButtonReleased(.Left) && area.width >= 1 && area.height >= 1 {
			ready = true
		}
	}

	return
}

@(private = "file", require_results)
end :: proc(global: ^state.State, area: raylib.Rectangle) -> error.Error {
	act := action.Vision {
		texture = global.frame.current,
		area    = area,
		mode    = global.vision.select,
	}

	global.process, global.vision, global.tool = {}, {}, .None

	err := action.vision(act)
	if err == .No_Text_Found {
		state.show_vision_failed_message(&global.message)
		return .None
	}

	state.show_copied_message(&global.message)
	return err
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
