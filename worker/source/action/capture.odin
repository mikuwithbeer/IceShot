package action

import "../native"

import "vendor:raylib"

Capture_Action :: struct {
	width:   i32,
	height:  i32,
	texture: raylib.Texture2D,
}

capture_action :: proc() -> (act: Capture_Action, err: Action_Error) {
	ok := native.unsafe_init_capture()
	if !ok {
		err = .Accessibility_Error
		return
	}

	size: native.Unsafe_Point2D
	ok = native.unsafe_size_capture(&size)
	if !ok {
		err = .Accessibility_Error
		return
	}

	capture: native.Unsafe_Capture
	ok = native.unsafe_load_capture({0, 0}, size, &capture)
	if !ok {
		err = .Out_Of_Memory
		return
	}

	defer native.unsafe_free_capture(&capture)

	image := raylib.Image {
		data    = capture.data,
		width   = i32(capture.width),
		height  = i32(capture.height),
		mipmaps = 1,
		format  = .UNCOMPRESSED_R8G8B8A8,
	}

	act.width = image.width
	act.height = image.height
	act.texture = raylib.LoadTextureFromImage(image)

	raylib.SetTextureFilter(act.texture, .TRILINEAR)

	return
}
