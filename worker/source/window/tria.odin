package window

import "../action"
import "../error"
import "../state"

import "vendor:raylib"

@(private, require_results)
process_tria :: proc(global: ^state.State, view: ^Viewer) -> error.Error {
	if global.tool != .Tria {
		return .None
	}

	color, ready := process_triangle_creation(global, view)
	if ready {
		apply_triangle(global, color) or_return
	} else {
		draw_triangle_pointer(global, color, view.camera.zoom)
	}

	return .None
}

@(private = "file", require_results)
process_triangle_creation :: proc(
	global: ^state.State,
	view: ^Viewer,
) -> (
	color: raylib.Color,
	ready: bool,
) {
	color = {global.tria.color.r, global.tria.color.g, global.tria.color.b, 255} // Keep it fully opaque

	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		global.tria.point[global.tria.index] = global.frame.world
		global.tria.index += 1

		if global.tria.index == 3 {
			ready = true
		}
	}

	return
}

@(private = "file")
draw_triangle_pointer :: proc(global: ^state.State, color: raylib.Color, zoom: f32) {
	for point in global.tria.point[:global.tria.index] {
		raylib.DrawCircle(i32(point.x), i32(point.y), 10 * zoom, color)
	}
}

@(private = "file", require_results)
apply_triangle :: proc(global: ^state.State, color: raylib.Color) -> error.Error {
	act := action.Tria {
		texture = global.frame.current,
		point   = global.tria.point,
		color   = color,
	}

	result := action.handle_tria(act) or_return

	replace_current_texture(global, result.texture)
	state.push_history(&global.history, act) or_return

	state.show_idle_message(&global.message)

	global.process, global.tria, global.tool = {}, {}, .None // Reset the process state

	return .None
}
