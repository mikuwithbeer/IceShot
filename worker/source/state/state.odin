package state

import "../error"

import "vendor:raylib"

Tool :: enum {
	None,
	Crop,
	Rect,
	Pick,
}

Crop :: struct {
	dragging:   bool,
	start, end: [2]f32,
}

Rect :: struct {
	using _: Crop,
	empty:   bool,
	color:   raylib.Color,
}

Pick :: struct {
	dropping: bool,
	selected: i32,
	point:    [2]f32,
	color:    raylib.Color,
	image:    raylib.Image,
}

Frame :: struct {
	initial, current:            raylib.Texture2D,
	tiles:                       raylib.RenderTexture2D,
	font:                        raylib.Font,
	dpi, cursor, render, screen: [2]f32,
	fly, style, board:           bool,
}

Process :: struct {
	crop, rect, pick, undo, copy, save: bool,
}

State :: struct {
	tool:    Tool,
	crop:    Crop,
	rect:    Rect,
	pick:    Pick,
	frame:   Frame,
	process: Process,
	history: History,
}

@(require_results)
init_state :: proc(allocator := context.allocator) -> (state: State, err: error.Error) {
	state.history = init_history(allocator = allocator) or_return
	return
}

free_state :: proc(state: ^State) {
	free_history(&state.history)
}
