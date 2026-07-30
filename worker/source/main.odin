package main

import "core:fmt"

import "native"

import stbi "vendor:stb/image"

main :: proc() {
	if !native.init_capture() {
		return
	}

	size: native.Point2D
	ok := native.size_capture(&size)
	if !ok {
		return
	}

	capture: native.Capture
	ok = native.load_capture({size.x / 2 - 250, size.y / 2 - 250}, {500, 500}, &capture)
	if !ok {
		return
	}

	defer native.free_capture(&capture)

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
