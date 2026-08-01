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

Read :: struct {
	texture: raylib.Texture2D,
}

Copy :: distinct Read

Save :: distinct Copy

Action :: union {
	Crop,
	Rect,
	Pick,
	Read,
	Copy,
	Save,
}
