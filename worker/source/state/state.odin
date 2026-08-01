package state

import "../error"

import "vendor:raylib"

Crop :: struct {
	running:  bool,
	dragging: bool,
	start:    [2]f32,
	end:      [2]f32,
}

Frame :: struct {
	fly:     bool,
	dpi:     [2]f32,
	cursor:  [2]f32,
	render:  [2]f32,
	screen:  [2]f32,
	font:    raylib.Font,
	initial: raylib.Texture2D,
	current: raylib.Texture2D,
	style:   bool,
	board:   bool,
	tiles:   raylib.RenderTexture2D,
}

State :: struct {
	crop:    Crop,
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
