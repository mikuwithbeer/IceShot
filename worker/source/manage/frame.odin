package manage

import "vendor:raylib"

Manage_Frame :: struct {
	fly:    bool,
	dpi:    [2]f32,
	cursor: [2]f32,
	render: [2]f32,
	font:   raylib.Font,
	shot:   raylib.Texture2D,
}
