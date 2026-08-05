package tools

import "../action"
import "../error"
import "../state"

import "vendor:raylib"

@(require_results)
triangle :: proc(global: ^state.State) -> error.Error {
	if global.tool != .Triangle {
		return .None
	}

	color, ready := start(global)
	if ready {
		end(global, color) or_return
	} else {
		show(global, color)
	}

	return .None
}

@(private = "file", require_results)
start :: proc(global: ^state.State) -> (color: raylib.Color, ready: bool) {
	// Keep it fully opaque.
	color = {global.triangle.color.r, global.triangle.color.g, global.triangle.color.b, 255}

	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		global.triangle.point[global.triangle.index] = global.frame.world
		global.triangle.index += 1

		if global.triangle.index == 3 {
			ready = true
		}
	}

	return
}

@(private = "file", require_results)
end :: proc(global: ^state.State, color: raylib.Color) -> error.Error {
	act := action.Triangle {
		texture = global.frame.current,
		point   = global.triangle.point,
		color   = color,
	}

	result := action.triangle(act) or_return
	replace_current_texture(global, result.texture)

	state.push_history(&global.history, act) or_return
	state.show_idle_message(&global.message)

	global.process, global.triangle, global.tool = {}, {}, .None // Reset the process state
	return .None
}

@(private = "file")
show :: proc(global: ^state.State, color: raylib.Color) {
	for point in global.triangle.point[:global.triangle.index] {
		raylib.DrawCircle(i32(point.x), i32(point.y), 10 * global.frame.camera.zoom, color)
	}
}
