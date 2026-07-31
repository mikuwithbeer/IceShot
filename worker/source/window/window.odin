package window

import "vendor:raylib"

Window :: struct {
	viewer: Viewer,
	header: Header,
	cursor: [2]f32,
	render: [2]f32,
	closed: bool,
	inside: bool,
}

init_window :: proc() -> (gui: Window, ok: bool) {
	raylib.SetConfigFlags({.WINDOW_HIGHDPI, .WINDOW_RESIZABLE})
	raylib.InitWindow(800, 600, "IceShot")
	raylib.SetTargetFPS(60)

	gui.cursor = {0, 0}
	gui.render = {f32(raylib.GetRenderWidth()), f32(raylib.GetRenderHeight())}

	gui.closed = false
	gui.inside = false

	gui.viewer = init_viewer(&gui) or_return
	gui.header = init_header(&gui) or_return

	ok = true
	return
}

load_window :: proc(gui: ^Window) -> (ok: bool) {
	for {
		gui.closed = raylib.WindowShouldClose()
		if gui.closed {
			break
		}

		gui.cursor = raylib.GetMousePosition()
		gui.render = {f32(raylib.GetRenderWidth()), f32(raylib.GetRenderHeight())}

		gui.inside = gui.cursor.y > gui.header.panel_position.height

		raylib.BeginDrawing()
		defer raylib.EndDrawing()

		raylib.ClearBackground({255, 255, 255, 255})

		load_viewer(&gui.viewer, gui) or_return
		load_header(&gui.header, gui) or_return
	}

	ok = true
	return
}

free_window :: proc(gui: ^Window) {
	free_viewer(&gui.viewer)
	free_header(&gui.header)
}
