package window

import "../error"
import "../native"
import "../raylib"
import "../state"
import "../tools"

import "base:runtime"

Viewer :: struct {
	panning:    bool,
	cursor:     [2]f32,
	_allocator: runtime.Allocator,
}

@(private, require_results)
init_viewer :: proc(
	global: ^state.State,
	capture: ^native.Unsafe_Capture,
	allocator := context.allocator,
) -> (
	view: Viewer,
	err: error.Error,
) {
	view._allocator = allocator

	image := raylib.Image {
		data    = capture.data,
		width   = i32(capture.width),
		height  = i32(capture.height),
		mipmaps = 1,
		format  = .Uncompressed_RGBA8888,
	}

	texture := raylib.LoadTextureFromImage(image)
	raylib.SetTextureFilter(texture, .BiLinear)

	native.unsafe_free_capture(capture) // Already loaded as texture so free it

	global.frame.initial, global.frame.current = texture, texture

	scale := [2]f32 {
		global.frame.render.x / f32(texture.width),
		global.frame.render.y / f32(texture.height),
	}

	zoom := min(min(scale.x, scale.y), 1.0) // Never zoom in past the original size

	// Start with the image centred and ready to use.
	global.frame.camera = raylib.Camera2D {
		offset = {global.frame.render.x * 0.5, global.frame.render.y * 0.5},
		target = {f32(texture.width) * 0.5, f32(texture.height) * 0.5},
		zoom   = zoom,
	}

	return
}

@(private)
update_viewer :: proc(view: ^Viewer, global: ^state.State) {
	global.frame.camera.offset = {global.frame.render.x * 0.5, global.frame.render.y * 0.5}

	// Stay within the image.
	// Leave one pixel to avoid reading out of bounds.
	// It is only required inside picker and measure, must be fixed for other cases.
	global.frame.world = raylib.GetScreenToWorld2D(global.frame.absolute, global.frame.camera)
	global.frame.world = {
		clamp(global.frame.world.x, 0, f32(global.frame.current.width) - 1),
		clamp(global.frame.world.y, 0, f32(global.frame.current.height) - 1),
	}

	process_camera_drag(view, global)
	process_camera_move(global)
	process_camera_zoom(global)
}

@(private, require_results)
draw_viewer :: proc(view: ^Viewer, global: ^state.State) -> error.Error {
	raylib.BeginMode2D(global.frame.camera)
	defer raylib.EndMode2D()

	raylib.DrawTexture(global.frame.current, 0, 0, {255, 255, 255, 255})

	color_first, color_second := get_brand_color(global.frame.dark)

	// Every tool that do not run instantly are handled here.
	tools.make_crop(global, color_first, color_second) or_return
	tools.make_rectangle(global) or_return
	tools.make_line(global) or_return
	tools.make_triangle(global) or_return
	tools.make_picker(global, allocator = view._allocator) or_return
	tools.make_measure(global, color_first, allocator = view._allocator) or_return
	tools.make_vision(global, color_first, color_second) or_return

	return .None
}

@(private = "file")
process_camera_drag :: proc(view: ^Viewer, global: ^state.State) {
	if !view.panning &&
	   global.frame.fly &&
	   raylib.IsKeyDown(.Space) &&
	   raylib.IsMouseButtonPressed(.Left) {
		view.panning = true
		view.cursor = global.frame.absolute
	}

	if !view.panning {
		return
	}

	global.frame.fly = false

	if raylib.IsMouseButtonDown(.Left) {
		delta := global.frame.absolute - view.cursor
		global.frame.camera.target -= delta / global.frame.camera.zoom

		view.cursor = global.frame.absolute
	}

	if raylib.IsMouseButtonReleased(.Left) {
		view.panning = false
	}
}

@(private = "file")
process_camera_move :: proc(global: ^state.State) {
	super := raylib.IsKeyDown(.Left_Super) || raylib.IsKeyDown(.Right_Super)
	if super do return // No movement during shortcut usage

	speed := 2000.0 * raylib.GetFrameTime() / global.frame.camera.zoom // Keep movement the same

	if raylib.IsKeyDown(.A) || raylib.IsKeyDown(.Left) {
		global.frame.camera.target.x -= speed
	}

	if raylib.IsKeyDown(.D) || raylib.IsKeyDown(.Right) {
		global.frame.camera.target.x += speed
	}

	if raylib.IsKeyDown(.W) || raylib.IsKeyDown(.Up) {
		global.frame.camera.target.y -= speed
	}

	if raylib.IsKeyDown(.S) || raylib.IsKeyDown(.Down) {
		global.frame.camera.target.y += speed
	}
}

@(private = "file")
process_camera_zoom :: proc(global: ^state.State) {
	wheel := raylib.GetMouseWheelMove()
	if wheel != 0 && global.frame.fly {
		factor := 1.0 + (wheel * 0.1)
		global.frame.camera.zoom *= factor
	}

	global.frame.camera.zoom = clamp(global.frame.camera.zoom, 0.5, 10.0) // Avoid zooming too far in or out
}
