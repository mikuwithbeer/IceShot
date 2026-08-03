package action

import "core:time"

import "vendor:raylib"

Capture_Result :: struct {
	width:   i32,
	height:  i32,
	texture: raylib.Texture2D,
}

Crop_Result :: distinct Capture_Result

Rect_Result :: distinct Capture_Result

Line_Result :: distinct Capture_Result

RotC_Result :: distinct Capture_Result

Save_Result :: struct {
	date: time.Time,
	path: string,
}

Result :: union {
	Capture_Result,
	Crop_Result,
	Rect_Result,
	RotC_Result,
	Save_Result,
}

free_action_result :: proc(result: Result, allocator := context.allocator) {
	#partial switch res in result {
	case Save_Result:
		delete(res.path, allocator = allocator)
	}
}
