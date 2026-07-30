package window

import "vendor:raylib"

Window :: struct {
	viewer: Viewer,
	header: Header,
	render: [2]f32,
	closed: bool,
}

init_window :: proc() -> (gui: Window, ok: bool) {
	raylib.SetConfigFlags({.WINDOW_HIGHDPI, .WINDOW_RESIZABLE})
	raylib.InitWindow(800, 600, "IceShot")
	raylib.SetTargetFPS(60)

	gui.render = {f32(raylib.GetRenderWidth()), f32(raylib.GetRenderHeight())}
	gui.closed = false

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

		gui.render = {f32(raylib.GetRenderWidth()), f32(raylib.GetRenderHeight())}

		raylib.BeginDrawing()
		defer raylib.EndDrawing()

		raylib.ClearBackground({255, 255, 255, 255})

		load_viewer(gui, &gui.viewer) or_return
		load_header(gui, &gui.header) or_return
	}

	ok = true
	return
}

free_window :: proc(gui: ^Window) {
	free_viewer(&gui.viewer)
	free_header(&gui.header)
}
