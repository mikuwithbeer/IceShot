package main

import "native"
import raylib "vendor:raylib"

WINDOW_DEFAULT_X :: 800
WINDOW_DEFAULT_Y :: 600

main :: proc() {
	if !native.init_capture() {
		return
	}

	size: native.Point2D
	if !native.size_capture(&size) {
		return
	}

	raylib.SetConfigFlags({.WINDOW_HIGHDPI, .WINDOW_RESIZABLE})

	raylib.InitWindow(WINDOW_DEFAULT_X, WINDOW_DEFAULT_Y, "IceShot Capture")
	defer raylib.CloseWindow()

	raylib.SetTargetFPS(60)

	capture: native.Capture
	if !native.load_capture({0, 0}, size, &capture) {
		return
	}

	image := raylib.Image {
		data    = capture.data,
		width   = i32(capture.width),
		height  = i32(capture.height),
		mipmaps = 1,
		format  = .UNCOMPRESSED_R8G8B8A8,
	}

	texture := raylib.LoadTextureFromImage(image)
	defer raylib.UnloadTexture(texture)

	raylib.SetTextureFilter(texture, .TRILINEAR)
	native.free_capture(&capture)

	render_width := f32(raylib.GetRenderWidth())
	render_height := f32(raylib.GetRenderHeight())

	scale_x := render_width / f32(texture.width)
	scale_y := render_height / f32(texture.height)

	initial_zoom := min(scale_x, scale_y)
	if initial_zoom > 1.0 {
		initial_zoom = 1.0
	}

	camera := raylib.Camera2D {
		offset = {render_width * 0.5, render_height * 0.5},
		target = {f32(texture.width) * 0.5, f32(texture.height) * 0.5},
		zoom   = initial_zoom,
	}

	for !raylib.WindowShouldClose() {
		render_width = f32(raylib.GetRenderWidth())
		render_height = f32(raylib.GetRenderHeight())
		camera.offset = {render_width * 0.5, render_height * 0.5}

		dpi := raylib.GetWindowScaleDPI()
		wheel := raylib.GetMouseWheelMove()
		if wheel != 0 {
			mouse_logical := raylib.GetMousePosition()
			mouse_screen := raylib.Vector2{mouse_logical.x * dpi.x, mouse_logical.y * dpi.y}

			world_before := raylib.GetScreenToWorld2D(mouse_screen, camera)

			zoom_factor := 1.0 + (wheel * 0.1)
			camera.zoom = raylib.Clamp(camera.zoom * zoom_factor, 0.05, 20.0)

			world_after := raylib.GetScreenToWorld2D(mouse_screen, camera)

			camera.target.x += (world_before.x - world_after.x)
			camera.target.y += (world_before.y - world_after.y)
		}

		if raylib.IsMouseButtonDown(.MIDDLE) {
			delta_logical := raylib.GetMouseDelta()
			delta := raylib.Vector2{delta_logical.x * dpi.x, delta_logical.y * dpi.y}

			camera.target.x -= delta.x / camera.zoom
			camera.target.y -= delta.y / camera.zoom
		} else {
			speed := 2000.0 * raylib.GetFrameTime() / camera.zoom
			if raylib.IsKeyDown(.LEFT) {
				camera.target.x -= speed
			} else if raylib.IsKeyDown(.RIGHT) {
				camera.target.x += speed
			} else if raylib.IsKeyDown(.UP) {
				camera.target.y -= speed
			} else if raylib.IsKeyDown(.DOWN) {
				camera.target.y += speed
			}
		}

		raylib.BeginDrawing()
		defer raylib.EndDrawing()

		raylib.ClearBackground(raylib.Color{255, 255, 255, 255})

		raylib.BeginMode2D(camera)
		defer raylib.EndMode2D()

		raylib.DrawTexture(texture, 0, 0, raylib.WHITE)
	}
}
