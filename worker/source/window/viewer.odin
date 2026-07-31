package window

import "../action"

import "vendor:raylib"

Viewer :: struct {
	texture: raylib.Texture2D,
	camera:  raylib.Camera2D,
	speed:   f32,
	dpi:     [2]f32,
}

init_viewer :: proc(gui: ^Window) -> (view: Viewer, err: action.Action_Error) {
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

	return
}

load_viewer :: proc(view: ^Viewer, gui: ^Window) -> (err: action.Action_Error) {
	view.camera.offset = {gui.render.x * 0.5, gui.render.y * 0.5}

	view.speed = 2000.0 * raylib.GetFrameTime() / view.camera.zoom
	view.dpi = raylib.GetWindowScaleDPI()

	raylib.BeginMode2D(view.camera)
	defer raylib.EndMode2D()

	raylib.DrawTexture(view.texture, 0, 0, {255, 255, 255, 255})

	handle_zoom(view, gui)
	handle_move(view)
	handle_crop(view, gui)

	return
}

free_viewer :: proc(view: ^Viewer) {
	raylib.UnloadTexture(view.texture)
}

@(private = "file")
handle_zoom :: proc(view: ^Viewer, gui: ^Window) {
	wheel := raylib.GetMouseWheelMove()
	if wheel != 0 && gui.inside {
		absolute := raylib.Vector2{gui.cursor.x * view.dpi.x, gui.cursor.y * view.dpi.y}

		before := raylib.GetScreenToWorld2D(absolute, view.camera)

		factor := 1.0 + (wheel * 0.1)
		view.camera.zoom = raylib.Clamp(view.camera.zoom * factor, 0.5, 10.0)

		after := raylib.GetScreenToWorld2D(absolute, view.camera)

		view.camera.target.x += before.x - after.x
		view.camera.target.y += before.y - after.y
	}
}

@(private = "file")
handle_move :: proc(view: ^Viewer) {
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
}

@(private = "file")
handle_crop :: proc(view: ^Viewer, gui: ^Window) -> (err: action.Action_Error) {
	if !gui.manage.crop.running {
		return
	}

	absolute := raylib.Vector2{gui.cursor.x * view.dpi.x, gui.cursor.y * view.dpi.y}

	world := raylib.GetScreenToWorld2D(absolute, view.camera)
	world.x = raylib.Clamp(world.x, 0.0, f32(view.texture.width))
	world.y = raylib.Clamp(world.y, 0.0, f32(view.texture.height))

	if gui.inside {
		if raylib.IsMouseButtonPressed(.LEFT) {
			gui.manage.crop.dragging = true
			gui.manage.crop.start = {world.x, world.y}
			gui.manage.crop.end = {world.x, world.y}
		}
	}

	if gui.manage.crop.dragging {
		if raylib.IsMouseButtonDown(.LEFT) {
			gui.manage.crop.end = {world.x, world.y}
		}

		area := raylib.Rectangle {
			x      = min(gui.manage.crop.start.x, gui.manage.crop.end.x),
			y      = min(gui.manage.crop.start.y, gui.manage.crop.end.y),
			width  = abs(gui.manage.crop.start.x - gui.manage.crop.end.x),
			height = abs(gui.manage.crop.start.y - gui.manage.crop.end.y),
		}

		if raylib.IsMouseButtonReleased(.LEFT) {
			gui.manage.crop.dragging = false

			if area.width > 1.0 && area.height > 1.0 {
				act := action.crop_action(view.texture, area) or_return

				raylib.UnloadTexture(view.texture)
				view.texture = act.texture

				gui.manage.crop = {}
			}
		}

		raylib.DrawRectangleRec(area, {121, 191, 255, 80})
		raylib.DrawRectangleLinesEx(area, 2.0 / view.camera.zoom, {121, 191, 255, 255})
	}

	return .None
}
