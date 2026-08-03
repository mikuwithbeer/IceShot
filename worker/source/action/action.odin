package action

import "vendor:raylib"

Crop :: struct {
	texture: raylib.Texture2D,
	area:    raylib.Rectangle,
}

Rect :: struct {
	using _: Crop,
	empty:   bool,
	color:   raylib.Color,
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
	Pick,
	RotC,
	Rule,
	Read,
	Copy,
	Save,
}
