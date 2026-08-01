package window

import "../action"
import "../error"
import "../state"

import "base:runtime"

import "vendor:raylib"

Viewer :: struct {
	camera:     raylib.Camera2D,
	_allocator: runtime.Allocator,
}

@(require_results)
init_viewer :: proc(
	global: ^state.State,
	allocator := context.allocator,
) -> (
	view: Viewer,
	err: error.Error,
) {
	view._allocator = allocator

	result := action.handle_capture() or_return

	global.frame.initial = result.texture
	global.frame.current = result.texture

	scale := [2]f32 {
		global.frame.render.x / f32(result.width),
		global.frame.render.y / f32(result.height),
	}

	zoom := min(scale.x, scale.y)
	if zoom > 1.0 {
		zoom = 1.0
	}

	view.camera = raylib.Camera2D {
		offset = {global.frame.render.x * 0.5, global.frame.render.y * 0.5},
		target = {f32(result.width) * 0.5, f32(result.height) * 0.5},
		zoom   = zoom,
	}

	return
}

@(require_results)
load_viewer :: proc(view: ^Viewer, global: ^state.State) -> (err: error.Error) {
	view.camera.offset = {global.frame.render.x * 0.5, global.frame.render.y * 0.5}

	raylib.BeginMode2D(view.camera)
	defer raylib.EndMode2D()

	raylib.DrawTexture(global.frame.current, 0, 0, {255, 255, 255, 255})

	handle_move(view)
	handle_zoom(view, global)

	effect_crop(global, view) or_return

	return
}

@(private = "file")
handle_move :: proc(view: ^Viewer) {
	speed := 2000.0 * raylib.GetFrameTime() / view.camera.zoom

	if raylib.IsKeyDown(.LEFT) {
		view.camera.target.x -= speed
	}

	if raylib.IsKeyDown(.RIGHT) {
		view.camera.target.x += speed
	}

	if raylib.IsKeyDown(.UP) {
		view.camera.target.y -= speed
	}

	if raylib.IsKeyDown(.DOWN) {
		view.camera.target.y += speed
	}
}

@(private = "file")
handle_zoom :: proc(view: ^Viewer, global: ^state.State) {
	wheel := raylib.GetMouseWheelMove()
	if wheel != 0 && global.frame.fly {
		absolute := raylib.Vector2 {
			global.frame.cursor.x * global.frame.dpi.x,
			global.frame.cursor.y * global.frame.dpi.y,
		}

		before := raylib.GetScreenToWorld2D(absolute, view.camera)

		factor := 1.0 + (wheel * 0.1)
		view.camera.zoom = raylib.Clamp(view.camera.zoom * factor, 0.5, 10.0)

		after := raylib.GetScreenToWorld2D(absolute, view.camera)

		view.camera.target.x += before.x - after.x
		view.camera.target.y += before.y - after.y
	}
}
