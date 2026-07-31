package action

import "../native"

import "vendor:raylib"

Capture_Action :: struct {
	width:   i32,
	height:  i32,
	texture: raylib.Texture2D,
}

@(require_results)
capture_action :: proc() -> (Capture_Action, Action_Error) {
	ok := native.unsafe_init_capture()
	if !ok {
		return {}, .Accessibility_Error
	}

	size: native.Unsafe_Point2D
	ok = native.unsafe_size_capture(&size)
	if !ok {
		return {}, .Accessibility_Error

	}

	capture: native.Unsafe_Capture
	ok = native.unsafe_load_capture({0, 0}, size, &capture)
	if !ok {
		return {}, .Out_Of_Memory
	}

	defer native.unsafe_free_capture(&capture)

	image := raylib.Image {
		data    = capture.data,
		width   = i32(capture.width),
		height  = i32(capture.height),
		mipmaps = 1,
		format  = .UNCOMPRESSED_R8G8B8A8,
	}

	texture := raylib.LoadTextureFromImage(image)
	raylib.SetTextureFilter(texture, .TRILINEAR)

	return {width = image.width, height = image.height, texture = texture}, .None
}
