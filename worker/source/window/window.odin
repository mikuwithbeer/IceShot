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

	gui.state = state.init_state(allocator = allocator) or_return

	init_style(&gui.state.frame)

	gui.state.frame.screen = {f32(raylib.GetScreenWidth()), f32(raylib.GetScreenHeight())}
	gui.state.frame.render = {f32(raylib.GetRenderWidth()), f32(raylib.GetRenderHeight())}
	gui.state.frame.board = true

	gui.viewer = init_viewer(&gui.state, allocator = allocator) or_return
	gui.header = init_header(&gui.state, allocator = allocator) or_return

	return
}

@(require_results)
load_window :: proc(gui: ^Window) -> error.Error {
	for !raylib.WindowShouldClose() {
		update_frame(gui)
		draw_frame(gui) or_return
	}

	return .None
}

free_window :: proc(gui: ^Window) {
	free_frame(gui)
	state.free_state(&gui.state)
	raylib.CloseWindow()
}

@(private = "file")
update_frame :: proc(gui: ^Window) {
	screen := [2]f32{f32(raylib.GetScreenWidth()), f32(raylib.GetScreenHeight())}
	render := [2]f32{f32(raylib.GetRenderWidth()), f32(raylib.GetRenderHeight())}

	if screen != gui.state.frame.screen || render != gui.state.frame.render {
		gui.state.frame.screen = screen
		gui.state.frame.render = render
		gui.state.frame.board = true
	}

	gui.state.frame.cursor = raylib.GetMousePosition()

	gui.state.frame.dpi = raylib.GetWindowScaleDPI()

	{
		color_position := raylib.Rectangle{gui.state.frame.screen.x - 120, 80, 120, 120}

		fly_panel := gui.state.frame.cursor.y <= gui.header.panel.height
		fly_color :=
			(gui.state.tool == .Rect) &&
			raylib.CheckCollisionPointRec(gui.state.frame.cursor, color_position)


		gui.state.frame.fly = !(fly_panel || fly_color)
	}

	update_viewer(&gui.viewer, &gui.state)
}

@(private = "file")
draw_frame :: proc(gui: ^Window) -> error.Error {
	raylib.BeginDrawing()
	defer raylib.EndDrawing()

	draw_board(gui)

	draw_viewer(&gui.viewer, &gui.state) or_return
	load_header(&gui.header, &gui.state) or_return

	return .None
}

@(private = "file")
free_frame :: proc(gui: ^Window) {
	if gui.state.frame.initial.id != 0 {
		raylib.UnloadTexture(gui.state.frame.initial)
	}

	if gui.state.frame.current.id != 0 &&
	   gui.state.frame.current.id != gui.state.frame.initial.id {
		raylib.UnloadTexture(gui.state.frame.current)
	}

	if gui.state.frame.tiles.id != 0 {
		raylib.UnloadRenderTexture(gui.state.frame.tiles)
	}

	if gui.state.frame.font.texture.id != 0 {
		raylib.UnloadFont(gui.state.frame.font)
	}
}
