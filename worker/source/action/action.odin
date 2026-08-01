package action

import "vendor:raylib"

Crop :: struct {
	texture: raylib.Texture2D,
	area:    raylib.Rectangle,
}

Pick :: struct {
	mode:  i32,
	color: raylib.Color,
}

Copy :: struct {
	texture: raylib.Texture2D,
}

Save :: distinct Copy

Action :: union {
	Crop,
	Pick,
	Copy,
	Save,
}
