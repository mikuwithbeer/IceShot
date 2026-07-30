package window

import "../action"

import "vendor:raylib"

Viewer :: struct {
	texture: raylib.Texture2D,
	camera:  raylib.Camera2D,
	render:  [2]f32,
	speed:   f32,
}

init_viewer :: proc() -> (view: Viewer, ok: bool) {
	act := action.capture_action() or_return

	view.texture = act.texture
	view.render = {f32(raylib.GetRenderWidth()), f32(raylib.GetRenderHeight())}

	scale := [2]f32{view.render.x / f32(act.width), view.render.y / f32(act.height)}
	zoom := min(scale.x, scale.y) * 0.9
	if zoom > 1.0 {
		zoom = 1.0
	}

	view.camera = raylib.Camera2D {
		offset = {view.render.x * 0.5, view.render.y * 0.5},
		target = {f32(act.width) * 0.5, f32(act.height) * 0.5},
		zoom   = zoom,
	}

	ok = true
	return
}

load_viewer :: proc(view: ^Viewer) -> (ok: bool) {
	view.render = {f32(raylib.GetRenderWidth()), f32(raylib.GetRenderHeight())}
	view.camera.offset = {view.render.x * 0.5, view.render.y * 0.5}
	view.speed = 2000.0 * raylib.GetFrameTime() / view.camera.zoom

	raylib.BeginMode2D(view.camera)
	defer raylib.EndMode2D()

	raylib.DrawTexture(view.texture, 0, 0, raylib.WHITE)

	if raylib.IsKeyDown(.LEFT) {
		view.camera.target.x += view.speed
	}

	if raylib.IsKeyDown(.RIGHT) {
		view.camera.target.x -= view.speed
	}

	if raylib.IsKeyDown(.UP) {
		view.camera.target.y += view.speed
	}

	if raylib.IsKeyDown(.DOWN) {
		view.camera.target.y -= view.speed
	}

	ok = true
	return
}

free_viewer :: proc(view: ^Viewer) {
	raylib.UnloadTexture(view.texture)
}
