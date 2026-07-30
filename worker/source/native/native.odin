package native

import "core:c"

Capture :: struct {
	data:   rawptr,
	length: c.size_t,
	width:  c.size_t,
	height: c.size_t,
	stride: c.size_t,
}

Point2D :: struct {
	x: c.double,
	y: c.double,
}

foreign import _native "../../output/native.o"

@(default_calling_convention = "c")
foreign _native {
	init_capture :: proc() -> c.bool ---
	size_capture :: proc(point: ^Point2D) -> c.bool ---
	load_capture :: proc(position: Point2D, size: Point2D, capture: ^Capture) -> c.bool ---
	free_capture :: proc(result: ^Capture) ---
}
