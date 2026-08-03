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
) -> error.Error {
	// Also avoid accidental actions while using dropdown.
	if global.tool != .Pick || global.pick.active {
		return .None
	}

	// Avoid loading the same image data more than once.
	if global.pick.image.data == nil {
		global.pick.image = raylib.LoadImageFromTexture(global.frame.current)
		global.pick.pixels = raylib.LoadImageColors(global.pick.image)
	}

	mode, color, ready := process_color_pick(global, view)
	if ready {
		apply_pick(global, mode, color, allocator = allocator) or_return
	}

	return .None
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
	global.pick.pixel =
		global.pick.pixels[i32(global.frame.world.y) * global.pick.image.width + i32(global.frame.world.x)]

	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		mode = global.pick.select
		color = global.pick.pixel
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
	// Leave nothing behind.
	global.process = {}
	global.pick = {}
	global.tool = .None

	raylib.UnloadImageColors(global.pick.pixels)
	raylib.UnloadImage(global.pick.image)

	act := action.Pick {
		mode  = mode,
		color = color,
	}

	action.handle_pick(act, allocator = allocator) or_return
	state.show_copied_message(&global.message)

	return .None
}
