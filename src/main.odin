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

foreign import capture "../build/capture.o"

@(default_calling_convention = "c")
foreign capture {
	init_capture :: proc() -> c.bool ---
	size_capture :: proc() -> Vector2 ---
	load_capture :: proc(position: Vector2, size: Vector2) -> Capture ---
	free_capture :: proc(result: ^Capture) ---
}

main :: proc() {
	if !init_capture() {
		return
	}

	size := size_capture()

	capture := load_capture({size.x / 2 - 250, size.y / 2 - 250}, {500, 500})
	if capture.data == nil {
		return
	}

	defer free_capture(&capture)

	stbi.write_jpg(
		"capture.jpg",
		i32(capture.width),
		i32(capture.height),
		4,
		capture.data,
		i32(capture.stride),
	)

	fmt.println("wrote to capture.jpg")
}
