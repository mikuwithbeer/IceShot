package main

import "core:c"
import "core:fmt"
import stbi "vendor:stb/image"

Capture :: struct {
	data:   rawptr,
	length: c.size_t,
	width:  c.size_t,
	height: c.size_t,
	stride: c.size_t,
}

Vector2 :: struct {
	x: c.double,
	y: c.double,
}

foreign import _wrapper "../build/wrapper.o"

@(default_calling_convention = "c")
foreign _wrapper {
	init_capture :: proc() -> c.bool ---
	size_capture :: proc() -> Vector2 ---
	load_capture :: proc(position: Vector2, size: Vector2, capture: ^Capture) -> bool ---
	free_capture :: proc(result: ^Capture) ---
}

main :: proc() {
	if !init_capture() {
		return
	}

	size := size_capture()

	capture: Capture
	ok := load_capture({size.x / 2 - 250, size.y / 2 - 250}, {500, 500}, &capture)
	if !ok {
		return
	}

	defer free_capture(&capture)

	stbi.write_png(
		"capture.png",
		i32(capture.width),
		i32(capture.height),
		4,
		capture.data,
		i32(capture.stride),
	)

	fmt.println("wrote to capture.png")
}
