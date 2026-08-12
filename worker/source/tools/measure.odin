package tools

import "../action"
import "../error"
import "../raylib"
import "../state"

@(require_results)
make_measure :: proc(
	global: ^state.State,
	color: raylib.Color,
	allocator := context.allocator,
) -> error.Error {
	// Also avoid accidental actions while using dropdown.
	if global.tool != .Measure || global.measure.active {
		return .None
	}

	// Avoid loading the same image data more than once.
	if global.measure.image.data == nil {
		global.measure.image = raylib.LoadImageFromTexture(global.frame.current)
		global.measure.pixels = raylib.LoadImageColors(global.measure.image)
	}

	ready := start(global)
	if ready {
		end(global, allocator = allocator) or_return
	} else {
		show(global, color)
	}

	return .None
}

free_measure :: proc(global: ^state.State) {
	raylib.UnloadImageColors(global.measure.pixels)
	raylib.UnloadImage(global.measure.image)
	global.measure = {}

	global.tool = .None
	global.process.measure = false
}

@(private = "file", require_results)
start :: proc(global: ^state.State) -> bool {
	world := [2]i32{i32(global.frame.world.x), i32(global.frame.world.y)}
	global.measure.pixel = global.measure.pixels[world.y * global.measure.image.width + world.x]

	// Measure how far the match goes to the left.
	for x := i32(global.frame.world.x); x >= 0; x -= 1 {
		if global.measure.pixels[world.y * global.measure.image.width + x] !=
		   global.measure.pixel {
			break
		}

		global.measure.bound[0] = world.x - x
	}

	// Measure how far the match goes to the right.
	for x := i32(global.frame.world.x); x < global.measure.image.width; x += 1 {
		if global.measure.pixels[world.y * global.measure.image.width + x] !=
		   global.measure.pixel {
			break
		}

		global.measure.bound[1] = x - world.x
	}

	// Measure how far the match goes to the upwards.
	for y := i32(global.frame.world.y); y >= 0; y -= 1 {
		if global.measure.pixels[y * global.measure.image.width + world.x] !=
		   global.measure.pixel {
			break
		}

		global.measure.bound[2] = world.y - y
	}

	// Measure how far the match goes to the downwards.
	for y := i32(global.frame.world.y); y < global.measure.image.height; y += 1 {
		if global.measure.pixels[y * global.measure.image.width + world.x] !=
		   global.measure.pixel {
			break
		}

		global.measure.bound[3] = y - world.y
	}

	if global.frame.fly && raylib.IsMouseButtonPressed(.Left) {
		return true
	}

	return false
}

@(private = "file", require_results)
end :: proc(global: ^state.State, allocator := context.allocator) -> error.Error {
	defer free_measure(global)

	act := action.Measure {
		dpi  = global.frame.dpi,
		mode = global.measure.select,
		size = {
			global.measure.bound[0] + global.measure.bound[1], // Work out the full width
			global.measure.bound[2] + global.measure.bound[3], // Work out the full height
		},
	}

	action.measure(act, allocator = allocator) or_return
	state.show_copied_message(&global.message)

	return .None
}

@(private = "file")
show :: proc(global: ^state.State, color: raylib.Color) {
	// Show the horizontal span.
	raylib.DrawLineEx(
		{global.frame.world.x - f32(global.measure.bound[0]), global.frame.world.y},
		{global.frame.world.x + f32(global.measure.bound[1]), global.frame.world.y},
		2 / global.frame.camera.zoom,
		color,
	)

	// Show the vertical span.
	raylib.DrawLineEx(
		{global.frame.world.x, global.frame.world.y - f32(global.measure.bound[2])},
		{global.frame.world.x, global.frame.world.y + f32(global.measure.bound[3])},
		2 / global.frame.camera.zoom,
		color,
	)
}
