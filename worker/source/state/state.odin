package state

import "../error"
import "../raylib"

Tool :: enum {
	None,
	Crop,
	Rectangle,
	Line,
	Triangle,
	Picker,
	Measure,
	Vision,
}

Crop :: struct {
	dragging:   bool,
	start, end: [2]f32,
}

Rectangle :: struct {
	dragging:   bool,
	start, end: [2]f32,
	empty:      bool,
	width:      f32,
	color:      raylib.Color,
}

Line :: struct {
	using _: Crop,
	width:   f32,
	color:   raylib.Color,
}

Triangle :: struct {
	index: u64,
	point: [3][2]f32,
	color: raylib.Color,
}

Picker :: struct {
	active: bool,
	select: i32,
	point:  [2]f32,
	image:  raylib.Image,
	pixel:  raylib.Color,
	pixels: [^]raylib.Color,
}

Measure :: struct {
	active: bool,
	select: i32,
	bound:  [4]i32,
	image:  raylib.Image,
	pixel:  raylib.Color,
	pixels: [^]raylib.Color,
}

Vision :: struct {
	dragging:   bool,
	active:     bool,
	start, end: [2]f32,
	select:     i32,
}

Frame :: struct {
	camera:                                       raylib.Camera2D,
	initial, current:                             raylib.Texture2D,
	tiles:                                        raylib.Render_Texture2D,
	font:                                         raylib.Font,
	dpi, cursor, absolute, render, screen, world: [2]f32,
	fly, style, board:                            bool,
}

Process :: struct {
	crop,
	rectangle,
	line,
	triangle,
	picker,
	rotate,
	measure,
	vision,
	undo,
	redo,
	share,
	copy,
	save: bool,
}

State :: struct {
	tool:      Tool,
	crop:      Crop,
	rectangle: Rectangle,
	line:      Line,
	triangle:  Triangle,
	picker:    Picker,
	measure:   Measure,
	vision:    Vision,
	frame:     Frame,
	process:   Process,
	config:    Config,
	history:   History,
	message:   Message,
}

@(require_results)
init_state :: proc(allocator := context.allocator) -> (state: State, err: error.Error) {
	config := init_config(allocator = allocator) or_return

	defer if err != .None do free_config(&config)

	history := init_history(allocator = allocator) or_return

	state.config = config
	state.history = history

	show_idle_message(&state.message)
	return
}

free_state :: proc(state: ^State) {
	free_history(&state.history)
	free_config(&state.config)
}
