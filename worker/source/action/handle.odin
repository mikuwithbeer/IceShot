package action

import "../error"
import "../native"

import "core:fmt"
import "core:strings"
import "core:time"

import "vendor:raylib"

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
		raylib.ImageDrawRectangleLines(&image, act.area, act.width, act.color)
	} else {
		raylib.ImageDrawRectangleRec(&image, act.area, act.color)
	}

	modified := raylib.LoadTextureFromImage(image)
	raylib.SetTextureFilter(modified, .BILINEAR)

	return {width = modified.width, height = modified.height, texture = modified}, .None
}

@(require_results)
handle_line :: proc(act: Line) -> (Line_Result, error.Error) {
	image := raylib.LoadImageFromTexture(act.texture)
	defer raylib.UnloadImage(image)

	fmt.println(act)

	raylib.ImageDrawLineEx(&image, act.start, act.end, act.width, act.color)

	modified := raylib.LoadTextureFromImage(image)
	raylib.SetTextureFilter(modified, .BILINEAR)

	return {width = modified.width, height = modified.height, texture = modified}, .None
}

@(require_results)
handle_tria :: proc(act: Tria) -> (Tria_Result, error.Error) {
	image := raylib.LoadImageFromTexture(act.texture)
	defer raylib.UnloadImage(image)

	raylib.ImageDrawTriangle(&image, act.point.x, act.point.y, act.point.z, act.color)

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
		// Default to hexadecimal formatting when no specific mode is selected.
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
	content: string
	switch act.mode {
	case 1:
		points: [2]f32 = {f32(act.size.x), f32(act.size.y)} / act.dpi
		content = fmt.aprintf("pt(%.1f, %.1f)", points.x, points.y, allocator = allocator)
	case:
		// Fallback to pixel units for all other modes.
		content = fmt.aprintf("px(%d, %d)", act.size.x, act.size.y, allocator = allocator)
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

	{
		result.date = time.now()

		year, month, day := time.year(result.date), time.month(result.date), time.day(result.date)
		hour, minute, second := time.clock_from_time(result.date)

		result.path = fmt.aprintf(
			"%s/%s/SCR-%04d%02d%02d-%02d%02d%02d.png",
			act.home,
			act.path,
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
		err = .Failed_To_Write_File
	}

	return
}
