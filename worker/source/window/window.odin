package window

import "vendor:raylib"

Window :: struct {
	viewer: Viewer,
	header: Header,
	cursor: [2]f32,
	render: [2]f32,
	inside: bool,
	_runs:  bool,
	_font:  raylib.Font,
}

init_window :: proc() -> (gui: Window, ok: bool) {
	raylib.SetConfigFlags({.WINDOW_HIGHDPI, .WINDOW_RESIZABLE})
	raylib.InitWindow(800, 600, "IceShot")
	raylib.SetTargetFPS(60)

	gui.cursor = {0, 0}
	gui.render = {f32(raylib.GetRenderWidth()), f32(raylib.GetRenderHeight())}

	gui.viewer = init_viewer(&gui) or_return
	gui.header = init_header(&gui) or_return

	handle_style(&gui) or_return

	ok = true
	return
}

load_window :: proc(gui: ^Window) -> (ok: bool) {
	for {
		gui._runs = !raylib.WindowShouldClose()
		if !gui._runs {
			break
		}

		gui.cursor = raylib.GetMousePosition()
		gui.render = {f32(raylib.GetRenderWidth()), f32(raylib.GetRenderHeight())}

		gui.inside = gui.cursor.y > gui.header.panel_position.height

		raylib.BeginDrawing()
		defer raylib.EndDrawing()

		handle_board(gui) or_return

		load_viewer(&gui.viewer, gui) or_return
		load_header(&gui.header, gui) or_return
	}

	ok = true
	return
}

free_window :: proc(gui: ^Window) {
	free_viewer(&gui.viewer)
	free_header(&gui.header)

	raylib.UnloadFont(gui._font)
}

@(private = "file")
handle_board :: proc(gui: ^Window) -> (ok: bool) {
	CELL_SIZE :: 8

	raylib.ClearBackground({255, 255, 255, 255})

	colors: [2]raylib.Color = {{30, 30, 35, 255}, {40, 40, 45, 255}}
	pixels: [2]i32 = {i32(gui.render.x) / CELL_SIZE + 1, i32(gui.render.y) / CELL_SIZE + 1}

	for x in 0 ..< pixels.x {
		for y in 0 ..< pixels.y {
			if (x + y) % 2 == 0 {
				raylib.DrawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE, colors.x)
			} else {
				raylib.DrawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE, colors.y)
			}
		}
	}

	ok = true
	return
}

@(private = "file")
handle_style :: proc(gui: ^Window) -> (ok: bool) {
	FONT_DATA :: #load("../../assets/fonts/IntelOneMono.ttf")

	raylib.GuiSetStyle(.DEFAULT, 0, 0x2C2C2CFF)
	raylib.GuiSetStyle(.DEFAULT, 1, 0x1C1C1CFF)
	raylib.GuiSetStyle(.DEFAULT, 2, transmute(i32)u32(0x999999FF))

	raylib.GuiSetStyle(.DEFAULT, 3, 0x2C2C2CFF)
	raylib.GuiSetStyle(.DEFAULT, 4, 0x2C2C2CFF)
	raylib.GuiSetStyle(.DEFAULT, 5, 0x79BFFFFF)

	raylib.GuiSetStyle(.DEFAULT, 6, 0x2C2C2CFF)
	raylib.GuiSetStyle(.DEFAULT, 7, 0x1C1C1CFF)
	raylib.GuiSetStyle(.DEFAULT, 8, 0x79BFFFFF)

	raylib.GuiSetStyle(.DEFAULT, 9, 0x2C2C2CFF)
	raylib.GuiSetStyle(.DEFAULT, 10, 0x1C1C1CFF)

	raylib.GuiSetStyle(.DEFAULT, 18, 0x2C2C2CFF)
	raylib.GuiSetStyle(.DEFAULT, 19, 0x1C1C1CFF)

	raylib.GuiSetStyle(.DEFAULT, 16, 0x00000016)
	raylib.GuiSetStyle(.DEFAULT, 17, 0x00000000)
	raylib.GuiSetStyle(.DEFAULT, 20, 0x00000018)

	gui._font = raylib.LoadFontFromMemory(
		".ttf",
		raw_data(FONT_DATA),
		i32(len(FONT_DATA)),
		64,
		nil,
		0,
	)

	raylib.SetTextureFilter(gui._font.texture, .TRILINEAR)
	raylib.GuiSetFont(gui._font)

	ok = true
	return
}
