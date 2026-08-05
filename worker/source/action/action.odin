package action

import "../error"
import "../native"

import "core:fmt"
import "core:strings"
import "core:time"

import "vendor:raylib"

Crop :: struct {
	texture: raylib.Texture2D,
	area:    raylib.Rectangle,
}

Rectangle :: struct {
	texture: raylib.Texture2D,
	area:    raylib.Rectangle,
	empty:   bool,
	width:   i32,
	color:   raylib.Color,
}

Line :: struct {
	texture:    raylib.Texture2D,
	start, end: [2]f32,
	width:      i32,
	color:      raylib.Color,
}

Triangle :: struct {
	texture: raylib.Texture2D,
	point:   [3][2]f32,
	color:   raylib.Color,
}

Picker :: struct {
	mode:  i32,
	color: raylib.Color,
}

Rotate :: struct {
	texture: raylib.Texture2D,
}

Measure :: struct {
	dpi:  [2]f32,
	mode: i32,
	size: [2]i32,
}

Read :: struct {
	texture: raylib.Texture2D,
}

Copy :: struct {
	texture: raylib.Texture2D,
}

Save :: struct {
	texture: raylib.Texture2D,
	home:    string,
	path:    string,
}

Action :: union {
	Crop,
	Rectangle,
	Line,
	Triangle,
	Picker,
	Rotate,
	Measure,
	Read,
	Copy,
	Save,
}

Result :: struct {
	texture: raylib.Texture2D,
	width:   i32,
	height:  i32,
}

@(require_results)
crop :: proc(act: Crop) -> (Result, error.Error) {
	image := raylib.LoadImageFromTexture(act.texture)
	defer raylib.UnloadImage(image)

	raylib.ImageCrop(&image, act.area)

	modified := raylib.LoadTextureFromImage(image)
	raylib.SetTextureFilter(modified, .BILINEAR)

	return {width = modified.width, height = modified.height, texture = modified}, .None
}

@(require_results)
rectangle :: proc(act: Rectangle) -> (Result, error.Error) {
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
line :: proc(act: Line) -> (Result, error.Error) {
	image := raylib.LoadImageFromTexture(act.texture)
	defer raylib.UnloadImage(image)

	fmt.println(act)

	raylib.ImageDrawLineEx(&image, act.start, act.end, act.width, act.color)

	modified := raylib.LoadTextureFromImage(image)
	raylib.SetTextureFilter(modified, .BILINEAR)

	return {width = modified.width, height = modified.height, texture = modified}, .None
}

@(require_results)
triangle :: proc(act: Triangle) -> (Result, error.Error) {
	image := raylib.LoadImageFromTexture(act.texture)
	defer raylib.UnloadImage(image)

	raylib.ImageDrawTriangle(&image, act.point.x, act.point.y, act.point.z, act.color)

	modified := raylib.LoadTextureFromImage(image)
	raylib.SetTextureFilter(modified, .BILINEAR)

	return {width = modified.width, height = modified.height, texture = modified}, .None
}

@(require_results)
picker :: proc(act: Picker, allocator := context.allocator) -> error.Error {
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
rotate :: proc(act: Rotate) -> (Result, error.Error) {
	image := raylib.LoadImageFromTexture(act.texture)
	defer raylib.UnloadImage(image)

	raylib.ImageRotateCW(&image)

	modified := raylib.LoadTextureFromImage(image)
	raylib.SetTextureFilter(modified, .BILINEAR)

	return {width = modified.width, height = modified.height, texture = modified}, .None
}

@(require_results)
measure :: proc(act: Measure, allocator := context.allocator) -> error.Error {
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
read :: proc(act: Read) -> error.Error {
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
copy :: proc(act: Copy) -> error.Error {
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
save :: proc(act: Save, allocator := context.allocator) -> error.Error {
	image := raylib.LoadImageFromTexture(act.texture)
	defer raylib.UnloadImage(image)

	current := time.now()

	year, month, day := time.year(current), time.month(current), time.day(current)
	hour, minute, second := time.clock_from_time(current)

	path := fmt.aprintf(
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

	defer delete(path, allocator = allocator)

	c_path, allocate_err := strings.clone_to_cstring(path, allocator = allocator)
	if allocate_err != .None {
		return .Out_Of_Memory
	}

	defer delete(c_path, allocator = allocator)

	ok := raylib.ExportImage(image, c_path)
	if !ok {
		return .Failed_To_Write_File
	}

	return .None
}
