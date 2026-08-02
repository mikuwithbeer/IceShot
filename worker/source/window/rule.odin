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
	if global.tool != .Rule {
		return .None
	}

	if global.rule.image.data == nil {
		global.rule.image = raylib.LoadImageFromTexture(global.frame.current)
		global.rule.pixels = raylib.LoadImageColors(global.rule.image)
	}

	horizontal, vertical, ready := process_rule_calculation(global, view)
	if ready {
		apply_rule(global, horizontal, vertical, allocator = allocator) or_return
	} else {
		draw_rule_overlay(global, view, view.camera.zoom)
	}

	return .None
}

@(private = "file", require_results)
process_rule_calculation :: proc(
	global: ^state.State,
	view: ^Viewer,
) -> (
	horizontal, vertical: i32,
	ready: bool,
) {
	position := [2]i32{i32(global.frame.world.x), i32(global.frame.world.y)}
	global.rule.pixel = global.rule.pixels[position.y * global.rule.image.width + position.x]

	for x := i32(global.frame.world.x); x >= 0; x -= 1 {
		if global.rule.pixels[position.y * global.rule.image.width + x] != global.rule.pixel {
			break
		}

		global.rule.bound[0] = position.x - x
	}

	for x := i32(global.frame.world.x); x < global.rule.image.width; x += 1 {
		if global.rule.pixels[position.y * global.rule.image.width + x] != global.rule.pixel {
			break
		}

		global.rule.bound[1] = x - position.x
	}

	for y := i32(global.frame.world.y); y >= 0; y -= 1 {
		if global.rule.pixels[y * global.rule.image.width + position.x] != global.rule.pixel {
			break
		}

		global.rule.bound[2] = position.y - y
	}

	for y := i32(global.frame.world.y); y < global.rule.image.height; y += 1 {
		if global.rule.pixels[y * global.rule.image.width + position.x] != global.rule.pixel {
			break
		}

		global.rule.bound[3] = y - position.y
	}

	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		horizontal = global.rule.bound[0] + global.rule.bound[1]
		vertical = global.rule.bound[2] + global.rule.bound[3]
		ready = true
	}

	return
}

@(private = "file")
draw_rule_overlay :: proc(global: ^state.State, view: ^Viewer, zoom: f32) {
	raylib.DrawLineEx(
		{global.frame.world.x - f32(global.rule.bound[0]), global.frame.world.y},
		{global.frame.world.x + f32(global.rule.bound[1]), global.frame.world.y},
		2 / zoom,
		{121, 191, 255, 255},
	)

	raylib.DrawLineEx(
		{global.frame.world.x, global.frame.world.y - f32(global.rule.bound[2])},
		{global.frame.world.x, global.frame.world.y + f32(global.rule.bound[3])},
		2 / zoom,
		{121, 191, 255, 255},
	)
}

@(private = "file", require_results)
apply_rule :: proc(
	global: ^state.State,
	horizontal, vertical: i32,
	allocator := context.allocator,
) -> error.Error {
	global.process = {}
	global.rule = {}
	global.tool = .None

	raylib.UnloadImageColors(global.rule.pixels)
	raylib.UnloadImage(global.rule.image)

	act := action.Rule{horizontal, vertical}

	action.handle_rule(act, allocator = allocator) or_return
	state.show_copied_message(&global.message)

	return .None
}
