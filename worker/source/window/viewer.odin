package window

import "../action"

import "vendor:raylib"

Viewer :: struct {
	texture: raylib.Texture2D,
	camera:  raylib.Camera2D,
	speed:   f32,
	dpi:     [2]f32,
}

init_viewer :: proc(gui: ^Window) -> (view: Viewer, ok: bool) {
	act := action.capture_action() or_return
	view.texture = act.texture

	scale := [2]f32{gui.render.x / f32(act.width), gui.render.y / f32(act.height)}
	zoom := min(scale.x, scale.y)
	if zoom > 1.0 {
		zoom = 1.0
	}

	view.camera = raylib.Camera2D {
		offset = {gui.render.x * 0.5, gui.render.y * 0.5},
		target = {f32(act.width) * 0.5, f32(act.height) * 0.5},
		zoom   = zoom,
	}

	ok = true
	return
}

load_viewer :: proc(gui: ^Window, view: ^Viewer) -> (ok: bool) {
	view.camera.offset = {gui.render.x * 0.5, gui.render.y * 0.5}
	view.speed = 2000.0 * raylib.GetFrameTime() / view.camera.zoom
	view.dpi = raylib.GetWindowScaleDPI()

	raylib.BeginMode2D(view.camera)
	defer raylib.EndMode2D()

	raylib.DrawTexture(view.texture, 0, 0, {255, 255, 255, 255})

	handle_zoom(view) or_return
	handle_move(view) or_return

	ok = true
	return
}

free_viewer :: proc(view: ^Viewer) {
	raylib.UnloadTexture(view.texture)
}

@(private = "file")
handle_zoom :: proc(view: ^Viewer) -> (ok: bool) {
	wheel := raylib.GetMouseWheelMove()
	cursor := raylib.GetMousePosition()

	if wheel != 0 {
		absolute := raylib.Vector2{cursor.x * view.dpi.x, cursor.y * view.dpi.y}

		before := raylib.GetScreenToWorld2D(absolute, view.camera)

		factor := 1.0 + (wheel * 0.1)
		view.camera.zoom = raylib.Clamp(view.camera.zoom * factor, 0.5, 10.0)

		after := raylib.GetScreenToWorld2D(absolute, view.camera)

		view.camera.target.x += before.x - after.x
		view.camera.target.y += before.y - after.y
	}

	ok = true
	return
}

@(private = "file")
handle_move :: proc(view: ^Viewer) -> (ok: bool) {
	if raylib.IsKeyDown(.LEFT) {
		view.camera.target.x -= view.speed
	}

	if raylib.IsKeyDown(.RIGHT) {
		view.camera.target.x += view.speed
	}

	if raylib.IsKeyDown(.UP) {
		view.camera.target.y -= view.speed
	}

	if raylib.IsKeyDown(.DOWN) {
		view.camera.target.y += view.speed
	}

	ok = true
	return
}
