package window

import "../error"
import "../native"
import "../raylib"
import "../state"

import "base:runtime"

WINDOW_WIDTH :: 960
WINDOW_HEIGHT :: 720
WINDOW_TITLE :: "IceShot"

Window :: struct {
	state:      state.State,
	viewer:     Viewer,
	header:     Header,
	_allocator: runtime.Allocator,
}

@(require_results)
init_window :: proc(
	capture: ^native.Unsafe_Capture,
	allocator := context.allocator,
) -> (
	gui: Window,
	err: error.Error,
) {
	gui._allocator = allocator

	when ODIN_DEBUG {
		raylib.SetTraceLogLevel(.Debug)
	} else {
		raylib.SetTraceLogLevel(.Error)
	}

	raylib.SetConfigFlags({.HighDPI, .Resizable, .VSync_Hint})
	raylib.SetTargetFPS(60)

	raylib.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)

	gui.state = state.init_state(allocator = allocator) or_return

	if gui.state.config.dark_mode {
		init_dark_mode(&gui.state.frame)
	} else {
		init_light_mode(&gui.state.frame)
	}

	gui.state.frame.screen = {f32(raylib.GetScreenWidth()), f32(raylib.GetScreenHeight())}
	gui.state.frame.render = {f32(raylib.GetRenderWidth()), f32(raylib.GetRenderHeight())}
	gui.state.frame.board = true

	gui.viewer = init_viewer(&gui.state, capture, allocator = allocator) or_return
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

	// Update the view when the window size changes.
	if screen != gui.state.frame.screen || render != gui.state.frame.render {
		gui.state.frame.screen, gui.state.frame.render = screen, render
		gui.state.frame.board = true
	}

	gui.state.frame.cursor, gui.state.frame.dpi =
		raylib.GetMousePosition(), raylib.GetWindowScaleDPI()

	gui.state.frame.absolute = {
		gui.state.frame.cursor.x * gui.state.frame.dpi.x,
		gui.state.frame.cursor.y * gui.state.frame.dpi.y,
	}

	// Avoid actions in areas used by the interface.
	{
		color_picker := raylib.Rectangle{gui.state.frame.screen.x - 200, 80, 200, 160}

		fly_panel := gui.state.frame.cursor.y <= gui.header.panel.height
		fly_color :=
			(gui.state.tool == .Rectangle ||
				gui.state.tool == .Line ||
				gui.state.tool == .Triangle) &&
			raylib.CheckCollisionPointRec(gui.state.frame.cursor, color_picker)

		gui.state.frame.fly = !(fly_panel || fly_color)
	}

	update_viewer(&gui.viewer, &gui.state)
}

@(private = "file", require_results)
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
