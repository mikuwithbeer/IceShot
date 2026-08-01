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

	color, ready := process_color_pick(global, view)
	if ready {
		apply_pick(global, color, allocator = allocator) or_return
	}

	return
}

@(private = "file", require_results)
process_color_pick :: proc(
	global: ^state.State,
	view: ^Viewer,
) -> (
	color: raylib.Color,
	ready: bool,
) {
	absolute := raylib.Vector2 {
		global.frame.cursor.x * global.frame.dpi.x,
		global.frame.cursor.y * global.frame.dpi.y,
	}

	world := raylib.GetScreenToWorld2D(absolute, view.camera)
	world.x = raylib.Clamp(world.x, 0.0, f32(global.frame.current.width))
	world.y = raylib.Clamp(world.y, 0.0, f32(global.frame.current.height))

	global.pick.color = raylib.GetImageColor(global.pick.image, i32(world.x), i32(world.y))

	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		color = global.pick.color
		ready = true
	}

	return
}

@(private = "file", require_results)
apply_pick :: proc(
	global: ^state.State,
	color: raylib.Color,
	allocator := context.allocator,
) -> error.Error {
	raylib.UnloadImage(global.pick.image)
	global.pick.image.data = nil
	global.tool = .None

	act := action.Pick {
		color = color,
	}

	_, err := action.handle_pick(act, allocator = allocator)
	if err != .None {
		return err
	}

	return .None
}
