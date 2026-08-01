package state

import "vendor:raylib"

Frame :: struct {
	fly:     bool,
	dpi:     [2]f32,
	cursor:  [2]f32,
	render:  [2]f32,
	screen:  [2]f32,
	font:    raylib.Font,
	initial: raylib.Texture2D,
	current: raylib.Texture2D,
}
