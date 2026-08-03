package action

import "vendor:raylib"

Crop :: struct {
	texture: raylib.Texture2D,
	area:    raylib.Rectangle,
}

Rect :: struct {
	using _: Crop,
	empty:   bool,
	width:   i32,
	color:   raylib.Color,
}

Line :: struct {
	texture:    raylib.Texture2D,
	start, end: [2]f32,
	width:      i32,
	color:      raylib.Color,
}

Pick :: struct {
	mode:  i32,
	color: raylib.Color,
}

RotC :: struct {
	texture: raylib.Texture2D,
}

Rule :: struct {
	dpi:  [2]f32,
	mode: i32,
	size: [2]i32,
}

Read :: distinct RotC

Copy :: distinct RotC

Save :: distinct RotC

Action :: union {
	Crop,
	Rect,
	Line,
	Pick,
	RotC,
	Rule,
	Read,
	Copy,
	Save,
}
