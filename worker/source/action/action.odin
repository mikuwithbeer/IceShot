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

Save :: struct {
	texture: raylib.Texture2D,
}

Action :: union {
	Crop,
	Pick,
	Save,
}
