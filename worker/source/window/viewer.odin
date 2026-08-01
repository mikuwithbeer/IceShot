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

update_viewer :: proc(view: ^Viewer, global: ^state.State) {
	view.camera.offset = {global.frame.render.x * 0.5, global.frame.render.y * 0.5}

	process_camera_move(view)
	process_camera_zoom(view, global)
	process_camera_clamp(view)
}

@(require_results)
draw_viewer :: proc(view: ^Viewer, global: ^state.State) -> (err: error.Error) {
	raylib.BeginMode2D(view.camera)
	defer raylib.EndMode2D()

	raylib.DrawTexture(global.frame.current, 0, 0, {255, 255, 255, 255})

	process_crop(global, view) or_return
	process_pick(global, view, allocator = view._allocator) or_return

	return
}

@(private)
replace_current_texture :: proc(global: ^state.State, texture: raylib.Texture2D) {
	if global.frame.current.id != global.frame.initial.id {
		raylib.UnloadTexture(global.frame.current)
	}

	global.frame.current = texture
}

@(private = "file")
process_camera_move :: proc(view: ^Viewer) {
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
process_camera_zoom :: proc(view: ^Viewer, global: ^state.State) {
	wheel := raylib.GetMouseWheelMove()

	if wheel != 0 && global.frame.fly {
		factor := 1.0 + (wheel * 0.1)
		view.camera.zoom *= factor
	}
}

@(private = "file")
process_camera_clamp :: proc(view: ^Viewer) {
	view.camera.zoom = raylib.Clamp(view.camera.zoom, 0.5, 10.0)
}
