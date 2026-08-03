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

@(private, require_results)
init_viewer :: proc(
	global: ^state.State,
	allocator := context.allocator,
) -> (
	view: Viewer,
	err: error.Error,
) {
	view._allocator = allocator

	result := action.handle_capture() or_return

	// Store both textures for the history.
	global.frame.initial, global.frame.current = result.texture, result.texture

	scale := [2]f32 {
		global.frame.render.x / f32(result.width),
		global.frame.render.y / f32(result.height),
	}

	// Never zoom in past the original size.
	zoom := min(min(scale.x, scale.y), 1.0)

	// Start with the image centred and ready to use.
	view.camera = raylib.Camera2D {
		offset = {global.frame.render.x * 0.5, global.frame.render.y * 0.5},
		target = {f32(result.width) * 0.5, f32(result.height) * 0.5},
		zoom   = zoom,
	}

	return
}

@(private)
update_viewer :: proc(view: ^Viewer, global: ^state.State) {
	view.camera.offset = {global.frame.render.x * 0.5, global.frame.render.y * 0.5}

	// Stay within the image.
	// Leave one pixel to avoid reading out of bounds.
	global.frame.world = raylib.GetScreenToWorld2D(global.frame.absolute, view.camera)
	global.frame.world = {
		clamp(global.frame.world.x, 0, f32(global.frame.current.width) - 1),
		clamp(global.frame.world.y, 0, f32(global.frame.current.height) - 1),
	}

	process_camera_move(view)
	process_camera_zoom(view, global)
}

@(private, require_results)
draw_viewer :: proc(view: ^Viewer, global: ^state.State) -> error.Error {
	raylib.BeginMode2D(view.camera)
	defer raylib.EndMode2D()

	raylib.DrawTexture(global.frame.current, 0, 0, raylib.WHITE)

	process_crop(global, view) or_return
	process_rect(global, view) or_return
	process_line(global, view) or_return
	process_pick(global, view, allocator = view._allocator) or_return
	process_rule(global, view, allocator = view._allocator) or_return

	return .None
}

@(private)
replace_current_texture :: proc(global: ^state.State, texture: raylib.Texture2D) {
	// Keep the initial texture for history replay.
	if global.frame.current.id != global.frame.initial.id {
		raylib.UnloadTexture(global.frame.current)
	}

	global.frame.current = texture
}

@(private = "file")
process_camera_move :: proc(view: ^Viewer) {
	speed := 2000.0 * raylib.GetFrameTime() / view.camera.zoom // Keep movement the same

	if raylib.IsKeyDown(.A) || raylib.IsKeyDown(.LEFT) {
		view.camera.target.x -= speed
	}

	if raylib.IsKeyDown(.D) || raylib.IsKeyDown(.RIGHT) {
		view.camera.target.x += speed
	}

	if raylib.IsKeyDown(.W) || raylib.IsKeyDown(.UP) {
		view.camera.target.y -= speed
	}

	if raylib.IsKeyDown(.S) || raylib.IsKeyDown(.DOWN) {
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

	view.camera.zoom = clamp(view.camera.zoom, 0.5, 10.0) // Avoid zooming too far in or out
}
