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
	horizontal: i32,
	vertical:   i32,
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
