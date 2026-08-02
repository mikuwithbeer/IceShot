package state

import "../error"

import "vendor:raylib"

Tool :: enum {
	None,
	Crop,
	Rect,
	Pick,
	Rule,
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
	image:    raylib.Image,
	pixel:    raylib.Color,
	pixels:   [^]raylib.Color,
}

Rule :: struct {
	bound:  [4]i32,
	image:  raylib.Image,
	pixel:  raylib.Color,
	pixels: [^]raylib.Color,
}

Frame :: struct {
	initial, current:                             raylib.Texture2D,
	tiles:                                        raylib.RenderTexture2D,
	font:                                         raylib.Font,
	dpi, cursor, absolute, render, screen, world: [2]f32,
	fly, style, board:                            bool,
}

Process :: struct {
	crop, rect, pick, rotc, rule, undo, read, copy, save: bool,
}

State :: struct {
	tool:    Tool,
	crop:    Crop,
	rect:    Rect,
	pick:    Pick,
	rule:    Rule,
	frame:   Frame,
	process: Process,
	history: History,
	message: Message,
}

@(require_results)
init_state :: proc(allocator := context.allocator) -> (state: State, err: error.Error) {
	state.history = init_history(allocator = allocator) or_return
	show_idle_message(&state.message)
	return
}

free_state :: proc(state: ^State) {
	free_history(&state.history)
}
