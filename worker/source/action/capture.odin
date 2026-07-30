package action

import "../native"

import "vendor:raylib"

Capture_Action :: struct {
	width:   i32,
	height:  i32,
	texture: raylib.Texture2D,
}

capture_action :: proc() -> (act: Capture_Action, ok: bool) {
	native.unsafe_init_capture() or_return

	size: native.Unsafe_Point2D
	native.unsafe_size_capture(&size) or_return

	capture: native.Unsafe_Capture
	native.unsafe_load_capture({0, 0}, size, &capture) or_return

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

	ok = true
	return
}
