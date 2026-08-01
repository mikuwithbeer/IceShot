package window

import "../error"
import "../state"

import "base:runtime"

import "vendor:raylib"

Window :: struct {
	state:      state.State,
	viewer:     Viewer,
	header:     Header,
	_allocator: runtime.Allocator,
}

@(require_results)
init_window :: proc(allocator := context.allocator) -> (gui: Window, err: error.Error) {
	gui._allocator = allocator

	raylib.SetConfigFlags({.WINDOW_HIGHDPI, .WINDOW_RESIZABLE, .VSYNC_HINT})
	raylib.InitWindow(800, 600, "IceShot")
	raylib.SetTargetFPS(60)

	handle_style(&gui)

	gui.state = state.init_state(allocator = allocator) or_return

	gui.state.frame.screen = {f32(raylib.GetScreenWidth()), f32(raylib.GetScreenHeight())}
	gui.state.frame.render = {f32(raylib.GetRenderWidth()), f32(raylib.GetRenderHeight())}

	gui.viewer = init_viewer(&gui.state, allocator = allocator) or_return
	gui.header = init_header(&gui.state, allocator = allocator) or_return

	return
}

@(require_results)
load_window :: proc(gui: ^Window) -> (err: error.Error) {
	for !raylib.WindowShouldClose() {
		gui.state.frame.screen = {f32(raylib.GetScreenWidth()), f32(raylib.GetScreenHeight())}
		gui.state.frame.render = {f32(raylib.GetRenderWidth()), f32(raylib.GetRenderHeight())}
		gui.state.frame.cursor = raylib.GetMousePosition()

		gui.state.frame.dpi = raylib.GetWindowScaleDPI()
		gui.state.frame.fly = gui.state.frame.cursor.y > gui.header.panel_position.height

		raylib.BeginDrawing()
		defer raylib.EndDrawing()

		handle_board(gui)

		load_viewer(&gui.viewer, &gui.state) or_return
		load_header(&gui.header, &gui.state) or_return
	}

	return
}

free_window :: proc(gui: ^Window) {
	state.free_state(&gui.state)

	raylib.UnloadTexture(gui.state.frame.initial)
	raylib.UnloadTexture(gui.state.frame.current)

	raylib.GuiSetFont(raylib.GetFontDefault())
	raylib.UnloadFont(gui.state.frame.font)

	raylib.CloseWindow()
}

@(private = "file")
handle_board :: proc(gui: ^Window) {
	CELL_SIZE :: 8

	raylib.ClearBackground({255, 255, 255, 255})

	pixels: [2]i32 = {
		i32(gui.state.frame.render.x) / CELL_SIZE + 1,
		i32(gui.state.frame.render.y) / CELL_SIZE + 1,
	}

	for x in 0 ..< pixels.x {
		for y in 0 ..< pixels.y {
			if (x + y) % 2 == 0 {
				raylib.DrawRectangle(
					x * CELL_SIZE,
					y * CELL_SIZE,
					CELL_SIZE,
					CELL_SIZE,
					{30, 30, 35, 255},
				)
			} else {
				raylib.DrawRectangle(
					x * CELL_SIZE,
					y * CELL_SIZE,
					CELL_SIZE,
					CELL_SIZE,
					{40, 40, 45, 255},
				)
			}
		}
	}
}

@(private = "file")
handle_style :: proc(gui: ^Window) {
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
	raylib.GuiSetStyle(.DEFAULT, 11, 0x333333FF)

	raylib.GuiSetStyle(.DEFAULT, 18, 0x2C2C2CFF)
	raylib.GuiSetStyle(.DEFAULT, 19, 0x1C1C1CFF)

	raylib.GuiSetStyle(.DEFAULT, 16, 0x00000016)
	raylib.GuiSetStyle(.DEFAULT, 17, 0x00000000)
	raylib.GuiSetStyle(.DEFAULT, 20, 0x00000018)

	raylib.GuiSetStyle(.BUTTON, 12, 0x00000001)

	font := raylib.LoadFontFromMemory(".ttf", raw_data(FONT_DATA), i32(len(FONT_DATA)), 64, nil, 0)

	raylib.SetTextureFilter(font.texture, .TRILINEAR)
	raylib.GuiSetFont(font)

	gui.state.frame.font = font
}
