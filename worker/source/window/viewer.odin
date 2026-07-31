package window

import "../action"
import "../manage"

import "base:runtime"

import "vendor:raylib"

Viewer :: struct {
	camera:     raylib.Camera2D,
	_allocator: runtime.Allocator,
}

@(require_results)
init_viewer :: proc(
	manager: ^manage.Manage,
	allocator := context.allocator,
) -> (
	view: Viewer,
	err: action.Action_Error,
) {
	view._allocator = allocator

	act := action.capture_action() or_return
	manager.frame.shot = act.texture

	scale := [2]f32 {
		manager.frame.render.x / f32(act.width),
		manager.frame.render.y / f32(act.height),
	}

	zoom := min(scale.x, scale.y)
	if zoom > 1.0 {
		zoom = 1.0
	}

	view.camera = raylib.Camera2D {
		offset = {manager.frame.render.x * 0.5, manager.frame.render.y * 0.5},
		target = {f32(act.width) * 0.5, f32(act.height) * 0.5},
		zoom   = zoom,
	}

	return
}

@(require_results)
load_viewer :: proc(view: ^Viewer, manager: ^manage.Manage) -> (err: action.Action_Error) {
	view.camera.offset = {manager.frame.render.x * 0.5, manager.frame.render.y * 0.5}

	raylib.BeginMode2D(view.camera)
	defer raylib.EndMode2D()

	raylib.DrawTexture(manager.frame.shot, 0, 0, {255, 255, 255, 255})

	handle_move(view)
	handle_zoom(view, manager)
	handle_crop(view, manager) or_return

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
handle_zoom :: proc(view: ^Viewer, manager: ^manage.Manage) {
	wheel := raylib.GetMouseWheelMove()
	if wheel != 0 && manager.frame.fly {
		absolute := raylib.Vector2 {
			manager.frame.cursor.x * manager.frame.dpi.x,
			manager.frame.cursor.y * manager.frame.dpi.y,
		}

		before := raylib.GetScreenToWorld2D(absolute, view.camera)

		factor := 1.0 + (wheel * 0.1)
		view.camera.zoom = raylib.Clamp(view.camera.zoom * factor, 0.5, 10.0)

		after := raylib.GetScreenToWorld2D(absolute, view.camera)

		view.camera.target.x += before.x - after.x
		view.camera.target.y += before.y - after.y
	}
}

@(private = "file", require_results)
handle_crop :: proc(view: ^Viewer, manager: ^manage.Manage) -> (err: action.Action_Error) {
	if !manager.crop.running {
		return
	}

	absolute := raylib.Vector2 {
		manager.frame.cursor.x * manager.frame.dpi.x,
		manager.frame.cursor.y * manager.frame.dpi.y,
	}

	world := raylib.GetScreenToWorld2D(absolute, view.camera)
	world.x = raylib.Clamp(world.x, 0.0, f32(manager.frame.shot.width))
	world.y = raylib.Clamp(world.y, 0.0, f32(manager.frame.shot.height))

	if manager.frame.fly && raylib.IsMouseButtonPressed(.LEFT) {
		manager.crop.dragging = true
		manager.crop.start = {world.x, world.y}
		manager.crop.end = {world.x, world.y}
	} else if manager.crop.dragging {
		if raylib.IsMouseButtonDown(.LEFT) {
			manager.crop.end = {world.x, world.y}
		}

		area := raylib.Rectangle {
			x      = min(manager.crop.start.x, manager.crop.end.x),
			y      = min(manager.crop.start.y, manager.crop.end.y),
			width  = abs(manager.crop.start.x - manager.crop.end.x),
			height = abs(manager.crop.start.y - manager.crop.end.y),
		}

		if raylib.IsMouseButtonReleased(.LEFT) {
			manager.crop.dragging = false

			if area.width > 1.0 && area.height > 1.0 {
				act := action.crop_action(manager.frame.shot, area) or_return

				raylib.UnloadTexture(manager.frame.shot)
				manager.frame.shot = act.texture

				manager.crop = {}
			}
		}

		raylib.DrawRectangleRec(area, {121, 191, 255, 80})
		raylib.DrawRectangleLinesEx(area, 2.0 / view.camera.zoom, {121, 191, 255, 255})
	}

	return
}
