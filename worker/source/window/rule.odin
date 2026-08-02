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
		draw_rule_overlay(global, view)
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
	absolute := raylib.Vector2 {
		global.frame.cursor.x * global.frame.dpi.x,
		global.frame.cursor.y * global.frame.dpi.y,
	}

	world := raylib.GetScreenToWorld2D(absolute, view.camera)
	world.x = raylib.Clamp(world.x, 0.0, f32(global.frame.current.width - 1))
	world.y = raylib.Clamp(world.y, 0.0, f32(global.frame.current.height - 1))

	{
		position := [2]i32{i32(world.x), i32(world.y)}
		distance := [4]i32{}

		global.rule.pixel = global.rule.pixels[position.y * global.rule.image.width + position.x]

		for x := i32(world.x); x >= 0; x -= 1 {
			if global.rule.pixels[position.y * global.rule.image.width + x] != global.rule.pixel {
				break
			}

			distance[0] = position.x - x
		}

		for x := i32(world.x); x < global.rule.image.width; x += 1 {
			if global.rule.pixels[position.y * global.rule.image.width + x] != global.rule.pixel {
				break
			}

			distance[1] = x - position.x
		}

		for y := i32(world.y); y >= 0; y -= 1 {
			if global.rule.pixels[y * global.rule.image.width + position.x] != global.rule.pixel {
				break
			}

			distance[2] = position.y - y
		}

		for y := i32(world.y); y < global.rule.image.height; y += 1 {
			if global.rule.pixels[y * global.rule.image.width + position.x] != global.rule.pixel {
				break
			}

			distance[3] = y - position.y
		}

		global.rule.bound = distance
	}

	if global.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		horizontal = global.rule.bound[0] + global.rule.bound[1]
		vertical = global.rule.bound[2] + global.rule.bound[3]
		ready = true
	}

	return
}

@(private = "file")
draw_rule_overlay :: proc(global: ^state.State, view: ^Viewer) {
	absolute := raylib.Vector2 {
		global.frame.cursor.x * global.frame.dpi.x,
		global.frame.cursor.y * global.frame.dpi.y,
	}

	world := raylib.GetScreenToWorld2D(absolute, view.camera)

	raylib.DrawLine(
		i32(world.x) - global.rule.bound[0],
		i32(world.y),
		i32(world.x) + global.rule.bound[1],
		i32(world.y),
		{121, 191, 255, 255},
	)

	raylib.DrawLine(
		i32(world.x),
		i32(world.y) - global.rule.bound[2],
		i32(world.x),
		i32(world.y) + global.rule.bound[3],
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
