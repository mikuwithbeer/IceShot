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

	ready := process_color_pick(global, view)
	if ready {
		apply_pick(global, allocator = allocator) or_return
	}

	return .None
}

@(private = "file", require_results)
process_color_pick :: proc(global: ^state.State, view: ^Viewer) -> bool {
	global.pick.pixel =
		global.pick.pixels[i32(global.frame.world.y) * global.pick.image.width + i32(global.frame.world.x)]

	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		return true
	}

	return false
}

@(private = "file", require_results)
apply_pick :: proc(global: ^state.State, allocator := context.allocator) -> error.Error {
	raylib.UnloadImageColors(global.pick.pixels)
	raylib.UnloadImage(global.pick.image)

	act := action.Pick {
		mode  = global.pick.select,
		color = global.pick.pixel,
	}

	action.handle_pick(act, allocator = allocator) or_return
	state.show_copied_message(&global.message)

	global.process, global.pick, global.tool = {}, {}, .None // Reset the process state

	return .None
}
