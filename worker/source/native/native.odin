package native

import "core:c"

Unsafe_Capture :: struct {
	data:   rawptr,
	length: c.size_t,
	width:  c.size_t,
	height: c.size_t,
	stride: c.size_t,
}

Unsafe_Point2D :: struct {
	x: c.double,
	y: c.double,
}

foreign import _native "../../output/native.o"

@(default_calling_convention = "c")
foreign _native {
	@(link_name = "init_capture")
	unsafe_init_capture :: proc() -> c.bool ---

	@(link_name = "size_capture")
	unsafe_size_capture :: proc(point: ^Unsafe_Point2D) -> c.bool ---

	@(link_name = "load_capture")
	unsafe_load_capture :: proc(position: Unsafe_Point2D, size: Unsafe_Point2D, capture: ^Unsafe_Capture) -> c.bool ---

	@(link_name = "free_capture")
	unsafe_free_capture :: proc(result: ^Unsafe_Capture) ---

	@(link_name = "load_paste")
	unsafe_load_paste :: proc(content: cstring) -> c.bool ---
}
