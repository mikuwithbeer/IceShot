package tools

import "../action"
import "../error"
import "../raylib"
import "../state"

@(require_results)
picker :: proc(global: ^state.State, allocator := context.allocator) -> error.Error {
	// Also avoid accidental actions while using dropdown.
	if global.tool != .Picker || global.picker.active {
		return .None
	}

	// Avoid loading the same image data more than once.
	if global.picker.image.data == nil {
		global.picker.image = raylib.LoadImageFromTexture(global.frame.current)
		global.picker.pixels = raylib.LoadImageColors(global.picker.image)
	}

	ready := start(global)
	if ready {
		end(global, allocator = allocator) or_return
	}

	return .None
}

@(private = "file", require_results)
start :: proc(global: ^state.State) -> bool {
	world: [2]i32 = {i32(global.frame.world.x), i32(global.frame.world.y)}
	global.picker.pixel = global.picker.pixels[world.y * global.picker.image.width + world.x]

	if global.frame.fly && raylib.IsMouseButtonPressed(.Left) {
		return true
	} else {
		return false
	}
}

@(private = "file", require_results)
end :: proc(global: ^state.State, allocator := context.allocator) -> error.Error {
	raylib.UnloadImageColors(global.picker.pixels)
	raylib.UnloadImage(global.picker.image)

	act := action.Picker {
		mode  = global.picker.select,
		color = global.picker.pixel,
	}

	action.picker(act, allocator = allocator) or_return
	state.show_copied_message(&global.message)

	global.process, global.picker, global.tool = {}, {}, .None
	return .None
}
