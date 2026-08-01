package state

import "../error"

import "vendor:raylib"

Tool :: enum {
	None,
	Crop,
	Pick,
}

Crop :: struct {
	dragging: bool,
	start:    [2]f32,
	end:      [2]f32,
}

Pick :: struct {
	dropping: bool,
	selected: i32,
	point:    [2]f32,
	color:    raylib.Color,
	image:    raylib.Image,
}

Frame :: struct {
	fly:     bool,
	dpi:     [2]f32,
	cursor:  [2]f32,
	render:  [2]f32,
	screen:  [2]f32,
	initial: raylib.Texture2D,
	current: raylib.Texture2D,
	style:   bool,
	board:   bool,
	tiles:   raylib.RenderTexture2D,
	font:    raylib.Font,
}

State :: struct {
	tool:    Tool,
	crop:    Crop,
	pick:    Pick,
	frame:   Frame,
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
