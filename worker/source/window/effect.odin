package window

import "../action"
import "../error"
import "../state"

import "vendor:raylib"

@(private, require_results)
effect_crop :: proc(global: ^state.State, view: ^Viewer) -> (err: error.Error) {
	if !global.crop.running {
		return
	}

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
	} else if global.crop.dragging {
		if raylib.IsMouseButtonDown(.LEFT) {
			global.crop.end = {world.x, world.y}
		}

		area := raylib.Rectangle {
			x      = min(global.crop.start.x, global.crop.end.x),
			y      = min(global.crop.start.y, global.crop.end.y),
			width  = abs(global.crop.start.x - global.crop.end.x),
			height = abs(global.crop.start.y - global.crop.end.y),
		}

		if raylib.IsMouseButtonReleased(.LEFT) {
			global.crop.dragging = false
			global.crop.running = false

			act := action.Crop {
				texture = global.frame.current,
				area    = area,
			}

			result := action.handle_crop(act) or_return

			if global.frame.current.id != global.frame.initial.id {
				raylib.UnloadTexture(global.frame.current)
			}

			global.frame.current = result.texture

			state.push_history(&global.history, act) or_return
		}

		raylib.DrawRectangleRec(area, {121, 191, 255, 80})
		raylib.DrawRectangleLinesEx(area, 2.0 / view.camera.zoom, {121, 191, 255, 255})
	}

	return
}

@(private, require_results)
effect_undo :: proc(global: ^state.State) -> (err: error.Error) {
	state.pop_history(&global.history) or_return

	raylib.UnloadTexture(global.frame.current)
	global.frame.current = global.frame.initial

	for value in global.history.actions {
		#partial switch act in value {
		case action.Crop:
			act_copy := act
			act_copy.texture = global.frame.current

			result := action.handle_crop(act_copy) or_return

			if global.frame.current.id != global.frame.initial.id {
				raylib.UnloadTexture(global.frame.current)
			}

			global.frame.current = result.texture
		}
	}

	return
}

@(private, require_results)
effect_save :: proc(global: ^state.State, allocator := context.allocator) -> (err: error.Error) {
	act := action.Save {
		texture = global.frame.current,
	}

	result := action.handle_save(act, allocator) or_return
	action.free_action_result(result, allocator)

	return
}
