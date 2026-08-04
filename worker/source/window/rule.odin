package window

import "../action"
import "../error"
import "../state"

import "vendor:raylib"

@(private, require_results)
process_rule :: proc(
	global: ^state.State,
	view: ^Viewer,
	allocator := context.allocator,
) -> error.Error {
	// Also avoid accidental actions while using dropdown.
	if global.tool != .Rule || global.rule.active {
		return .None
	}

	// Avoid loading the same image data more than once.
	if global.rule.image.data == nil {
		global.rule.image = raylib.LoadImageFromTexture(global.frame.current)
		global.rule.pixels = raylib.LoadImageColors(global.rule.image)
	}

	ready := process_rule_calculation(global, view)
	if ready {
		apply_rule(global, allocator = allocator) or_return
	} else {
		draw_rule_overlay(global, view, view.camera.zoom)
	}

	return .None
}

@(private = "file", require_results)
process_rule_calculation :: proc(global: ^state.State, view: ^Viewer) -> bool {
	position := [2]i32{i32(global.frame.world.x), i32(global.frame.world.y)}
	global.rule.pixel = global.rule.pixels[position.y * global.rule.image.width + position.x]

	// Measure how far the match goes to the left.
	for x := i32(global.frame.world.x); x >= 0; x -= 1 {
		if global.rule.pixels[position.y * global.rule.image.width + x] != global.rule.pixel {
			break
		}

		global.rule.bound[0] = position.x - x
	}

	// Measure how far the match goes to the right.
	for x := i32(global.frame.world.x); x < global.rule.image.width; x += 1 {
		if global.rule.pixels[position.y * global.rule.image.width + x] != global.rule.pixel {
			break
		}

		global.rule.bound[1] = x - position.x
	}

	// Measure how far the match goes to the upwards.
	for y := i32(global.frame.world.y); y >= 0; y -= 1 {
		if global.rule.pixels[y * global.rule.image.width + position.x] != global.rule.pixel {
			break
		}

		global.rule.bound[2] = position.y - y
	}

	// Measure how far the match goes to the downwards.
	for y := i32(global.frame.world.y); y < global.rule.image.height; y += 1 {
		if global.rule.pixels[y * global.rule.image.width + position.x] != global.rule.pixel {
			break
		}

		global.rule.bound[3] = y - position.y
	}

	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		return true
	}

	return false
}

@(private = "file")
draw_rule_overlay :: proc(global: ^state.State, view: ^Viewer, zoom: f32) {
	color, _ := get_brand_color(global.config.dark_mode)

	// Show the horizontal span.
	raylib.DrawLineEx(
		{global.frame.world.x - f32(global.rule.bound[0]), global.frame.world.y},
		{global.frame.world.x + f32(global.rule.bound[1]), global.frame.world.y},
		2 / zoom,
		color,
	)

	// Show the vertical span.
	raylib.DrawLineEx(
		{global.frame.world.x, global.frame.world.y - f32(global.rule.bound[2])},
		{global.frame.world.x, global.frame.world.y + f32(global.rule.bound[3])},
		2 / zoom,
		color,
	)
}

@(private = "file", require_results)
apply_rule :: proc(global: ^state.State, allocator := context.allocator) -> error.Error {
	raylib.UnloadImageColors(global.rule.pixels)
	raylib.UnloadImage(global.rule.image)

	act := action.Rule {
		dpi  = global.frame.dpi,
		mode = global.rule.select,
		size = {
			global.rule.bound[0] + global.rule.bound[1], // Work out the full width
			global.rule.bound[2] + global.rule.bound[3], // Work out the full height
		},
	}

	action.handle_rule(act, allocator = allocator) or_return
	state.show_copied_message(&global.message)

	global.process, global.rule, global.tool = {}, {}, .None // Reset the process state

	return .None
}
