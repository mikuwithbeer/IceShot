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

	modified := raylib.LoadTextureFromImage(image)
	raylib.SetTextureFilter(modified, .BILINEAR)

	return {width = modified.width, height = modified.height, texture = modified}, .None
}

@(require_results)
handle_rect :: proc(act: Rect) -> (Rect_Result, error.Error) {
	image := raylib.LoadImageFromTexture(act.texture)
	defer raylib.UnloadImage(image)

	if act.empty {
		raylib.ImageDrawRectangleLines(&image, act.area, 2, act.color)
	} else {
		raylib.ImageDrawRectangleRec(&image, act.area, act.color)
	}

	modified := raylib.LoadTextureFromImage(image)
	raylib.SetTextureFilter(modified, .BILINEAR)

	return {width = modified.width, height = modified.height, texture = modified}, .None
}

@(require_results)
handle_pick :: proc(act: Pick, allocator := context.allocator) -> error.Error {
	content: string
	switch act.mode {
	case 1:
		content = fmt.aprintf(
			"rgb(%d, %d, %d)",
			act.color.r,
			act.color.g,
			act.color.b,
			allocator = allocator,
		)
	case 2:
		content = fmt.aprintf(
			"rgb(%d, %d, %d, %d)",
			act.color.r,
			act.color.g,
			act.color.b,
			act.color.a,
			allocator = allocator,
		)
	case:
		// Let the default case reuse the hexadecimal formatter rather than repeating the same logic.
		content = fmt.aprintf(
			"#%02X%02X%02X",
			act.color.r,
			act.color.g,
			act.color.b,
			allocator = allocator,
		)
	}

	defer delete(content, allocator = allocator)

	c_content, err := strings.clone_to_cstring(content, allocator = allocator)
	if err != .None {
		return .Out_Of_Memory
	}

	defer delete(c_content, allocator = allocator)

	ok := native.unsafe_copy_value(c_content)
	if !ok {
		return .Not_Permitted
	} else {
		return .None
	}
}

@(require_results)
handle_rotc :: proc(act: RotC) -> (RotC_Result, error.Error) {
	image := raylib.LoadImageFromTexture(act.texture)
	defer raylib.UnloadImage(image)

	raylib.ImageRotateCW(&image)

	modified := raylib.LoadTextureFromImage(image)
	raylib.SetTextureFilter(modified, .BILINEAR)

	return {width = modified.width, height = modified.height, texture = modified}, .None
}

@(require_results)
handle_rule :: proc(act: Rule, allocator := context.allocator) -> error.Error {
	content := fmt.aprintf("(%d, %d)", act.horizontal, act.vertical, allocator = allocator)
	defer delete(content, allocator = allocator)

	c_content, err := strings.clone_to_cstring(content, allocator = allocator)
	if err != .None {
		return .Out_Of_Memory
	}

	defer delete(c_content, allocator = allocator)

	ok := native.unsafe_copy_value(c_content)
	if !ok {
		return .Not_Permitted
	} else {
		return .None
	}
}

@(require_results)
handle_read :: proc(act: Read) -> error.Error {
	image := raylib.LoadImageFromTexture(act.texture)
	defer raylib.UnloadImage(image)

	unsafe := native.Unsafe_Image{image.data, uint(image.width), uint(image.height)}

	ok := native.unsafe_copy_ocr(unsafe)
	if !ok {
		return .No_Text_Found
	} else {
		return .None
	}
}

@(require_results)
handle_copy :: proc(act: Copy) -> error.Error {
	image := raylib.LoadImageFromTexture(act.texture)
	defer raylib.UnloadImage(image)

	unsafe := native.Unsafe_Image{image.data, uint(image.width), uint(image.height)}

	ok := native.unsafe_copy_image(unsafe)
	if !ok {
		return .Not_Permitted
	} else {
		return .None
	}
}

@(require_results)
handle_save :: proc(
	act: Save,
	allocator := context.allocator,
) -> (
	result: Save_Result,
	err: error.Error,
) {
	image := raylib.LoadImageFromTexture(act.texture)
	defer raylib.UnloadImage(image)

	home := os.get_env_alloc("HOME", allocator = allocator)
	defer delete(home, allocator = allocator)

	{
		result.date = time.now()

		year, month, day := time.year(result.date), time.month(result.date), time.day(result.date)
		hour, minute, second := time.clock_from_time(result.date)

		result.path = fmt.aprintf(
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
	}

	c_path, allocate_err := strings.clone_to_cstring(result.path, allocator = allocator)
	if allocate_err != .None {
		err = .Out_Of_Memory
		return
	}

	defer delete(c_path, allocator = allocator)

	ok := raylib.ExportImage(image, c_path)
	if !ok {
		err = .Failed_To_Write
	}

	return
}
