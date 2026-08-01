package action

import "../error"
import "../native"

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

import "vendor:raylib"

@(require_results)
handle_capture :: proc() -> (Capture_Result, error.Error) {
	ok := native.unsafe_init_capture()
	if !ok {
		return {}, .Not_Permitted
	}

	size: native.Unsafe_Point2D
	ok = native.unsafe_size_capture(&size)
	if !ok {
		return {}, .Not_Permitted

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


@(require_results)
handle_crop :: proc(act: Crop) -> (Crop_Result, error.Error) {
	image := raylib.LoadImageFromTexture(act.texture)
	defer raylib.UnloadImage(image)

	raylib.ImageCrop(&image, act.area)

	cropped := raylib.LoadTextureFromImage(image)
	raylib.SetTextureFilter(cropped, .TRILINEAR)

	return {width = cropped.width, height = cropped.height, texture = cropped}, .None
}

@(require_results)
handle_save :: proc(act: Save, allocator := context.allocator) -> (Save_Result, error.Error) {
	image := raylib.LoadImageFromTexture(act.texture)
	defer raylib.UnloadImage(image)

	home := os.get_env_alloc("HOME", allocator = allocator)
	defer delete(home, allocator = allocator)

	date := time.now()
	year, month, day := time.year(date), time.month(date), time.day(date)
	hour, minute, second := time.clock_from_time(date)

	path := fmt.aprintf(
		"%s/Documents/Screenshots/SCR-%04d%02d%02d-%02d%02d%02d.png",
		home,
		year,
		month,
		day,
		hour,
		minute,
		second,
		allocator = allocator,
	)

	null_path := strings.clone_to_cstring(path, allocator = allocator)

	defer delete(null_path, allocator = allocator)

	ok := raylib.ExportImage(image, null_path)
	if !ok {
		return {}, .Failed_To_Write
	}

	return {date = date, path = path}, .None
}
