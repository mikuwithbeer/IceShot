package action

import "vendor:raylib"

Crop_Action :: struct {
	width:   i32,
	height:  i32,
	texture: raylib.Texture2D,
}

@(require_results)
crop_action :: proc(
	texture: raylib.Texture2D,
	area: raylib.Rectangle,
) -> (
	Crop_Action,
	Action_Error,
) {
	image := raylib.LoadImageFromTexture(texture)
	defer raylib.UnloadImage(image)

	raylib.ImageCrop(&image, area)

	cropped := raylib.LoadTextureFromImage(image)
	raylib.SetTextureFilter(cropped, .TRILINEAR)

	return {width = cropped.width, height = cropped.height, texture = cropped}, .None
}
