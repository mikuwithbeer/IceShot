package window

import "../action"
import "../error"
import "../state"

import "vendor:raylib"

@(private, require_results)
process_pick :: proc(
	global: ^state.State,
	view: ^Viewer,
	allocator := context.allocator,
) -> (
	err: error.Error,
) {
	if global.tool != .Pick {
		return
	}

	if global.pick.image.data == nil {
		global.pick.image = raylib.LoadImageFromTexture(global.frame.current)
	}

	if global.pick.dropping {
		return
	}

	mode, color, ready := process_color_pick(global, view)
	if ready {
		apply_pick(global, mode, color, allocator = allocator) or_return
	}

	return
}

@(private = "file", require_results)
process_color_pick :: proc(
	global: ^state.State,
	view: ^Viewer,
) -> (
	mode: i32,
	color: raylib.Color,
	ready: bool,
) {
	absolute := raylib.Vector2 {
		global.frame.cursor.x * global.frame.dpi.x,
		global.frame.cursor.y * global.frame.dpi.y,
	}

	world := raylib.GetScreenToWorld2D(absolute, view.camera)
	world.x = raylib.Clamp(world.x, 0.0, f32(global.frame.current.width - 1))
	world.y = raylib.Clamp(world.y, 0.0, f32(global.frame.current.height - 1))

	global.pick.color = raylib.GetImageColor(global.pick.image, i32(world.x), i32(world.y))

	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		mode = global.pick.selected
		color = global.pick.color
		ready = true
	}

	return
}

@(private = "file", require_results)
apply_pick :: proc(
	global: ^state.State,
	mode: i32,
	color: raylib.Color,
	allocator := context.allocator,
) -> error.Error {
	raylib.UnloadImage(global.pick.image)
	global.pick = {}
	global.tool = .None

	act := action.Pick {
		mode  = mode,
		color = color,
	}

	action.handle_pick(act, allocator = allocator) or_return
	return .None
}
