package window

import "vendor:raylib"

Window :: struct {
	viewer: Viewer,
	closed: bool,
}

init_window :: proc() -> (gui: Window, ok: bool) {
	raylib.SetConfigFlags({.WINDOW_HIGHDPI, .WINDOW_RESIZABLE})
	raylib.InitWindow(800, 600, "IceShot --- Edit")
	raylib.SetTargetFPS(60)

	gui.viewer = init_viewer() or_return
	gui.closed = false

	ok = true
	return
}

load_window :: proc(gui: ^Window) -> (ok: bool) {
	for {
		gui.closed = raylib.WindowShouldClose()
		if gui.closed {
			break
		}

		raylib.BeginDrawing()
		defer raylib.EndDrawing()

		raylib.ClearBackground(raylib.WHITE)

		load_viewer(&gui.viewer) or_return
	}

	ok = true
	return
}

free_window :: proc(gui: ^Window) {
	free_viewer(&gui.viewer)
}
