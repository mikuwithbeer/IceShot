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
	raylib.SetTextureFilter(texture, .BILINEAR)

	return {width = image.width, height = image.height, texture = texture}, .None
}


@(require_results)
handle_crop :: proc(act: Crop) -> (Crop_Result, error.Error) {
	image := raylib.LoadImageFromTexture(act.texture)
	defer raylib.UnloadImage(image)

	raylib.ImageCrop(&image, act.area)

	cropped := raylib.LoadTextureFromImage(image)
	raylib.SetTextureFilter(cropped, .BILINEAR)

	return {width = cropped.width, height = cropped.height, texture = cropped}, .None
}

handle_pick :: proc(act: Pick, allocator := context.allocator) -> (Pick_Result, error.Error) {
	hex: string
	if act.color.a == 255 {
		hex = fmt.aprintf(
			"#%02X%02X%02X",
			act.color.r,
			act.color.g,
			act.color.b,
			allocator = allocator,
		)
	} else {
		hex = fmt.aprintf(
			"#%02X%02X%02X%02X",
			act.color.r,
			act.color.g,
			act.color.b,
			act.color.a,
			allocator = allocator,
		)
	}

	defer delete(hex, allocator = allocator)

	c_hex, err := strings.clone_to_cstring(hex, allocator = allocator)
	if err != .None {
		return {}, .Out_Of_Memory
	}

	defer delete(c_hex, allocator = allocator)

	ok := native.unsafe_load_paste(c_hex)
	if !ok {
		return {}, .Not_Permitted
	}

	return {success = true}, .None
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

	c_path := strings.clone_to_cstring(path, allocator = allocator)
	defer delete(c_path, allocator = allocator)

	ok := raylib.ExportImage(image, c_path)
	if !ok {
		return {}, .Failed_To_Write
	}

	return {date = date, path = path}, .None
}
