package action

import "vendor:raylib"

Crop :: struct {
	texture: raylib.Texture2D,
	area:    raylib.Rectangle,
}

Save :: struct {
	texture: raylib.Texture2D,
}

Action :: union {
	Crop,
	Save,
}
