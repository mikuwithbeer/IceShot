package window

import "../error"
import "../raylib"
import "../state"
import "../tools"

import "base:runtime"

Header :: struct {
	panel:          raylib.Rectangle,
	color:          raylib.Rectangle,
	crop:           raylib.Rectangle,
	rectangle:      raylib.Rectangle,
	line:           raylib.Rectangle,
	triangle:       raylib.Rectangle,
	picker:         raylib.Rectangle,
	rotate:         raylib.Rectangle,
	measure:        raylib.Rectangle,
	undo:           raylib.Rectangle,
	redo:           raylib.Rectangle,
	read:           raylib.Rectangle,
	copy:           raylib.Rectangle,
	save:           raylib.Rectangle,
	picker_format:  raylib.Rectangle,
	picker_viewer:  raylib.Rectangle,
	rectangle_type: raylib.Rectangle,
	rectangle_size: raylib.Rectangle,
	line_size:      raylib.Rectangle,
	measure_type:   raylib.Rectangle,
	_allocator:     runtime.Allocator,
}

@(private, require_results)
init_header :: proc(
	global: ^state.State,
	allocator := context.allocator,
) -> (
	head: Header,
	err: error.Error,
) {
	head._allocator = allocator
	return
}

@(private, require_results)
load_header :: proc(head: ^Header, global: ^state.State) -> error.Error {
	layout_header(head, global)
	draw_header(head, global)
	process_header(head, global) or_return

	return .None
}

@(private = "file")
layout_header :: proc(head: ^Header, global: ^state.State) {
	head.panel = {0, 0, global.frame.screen.x, 72}
	head.color = {global.frame.screen.x - 200, 80, 168, 168}

	head.crop = {8, 32, 32, 32}
	head.rectangle = {48, 32, 32, 32}
	head.line = {88, 32, 32, 32}
	head.triangle = {128, 32, 32, 32}
	head.picker = {168, 32, 32, 32}
	head.rotate = {208, 32, 32, 32}
	head.measure = {248, 32, 32, 32}

	head.undo = {global.frame.screen.x - 200, 32, 32, 32}
	head.redo = {global.frame.screen.x - 160, 32, 32, 32}
	head.read = {global.frame.screen.x - 120, 32, 32, 32}
	head.copy = {global.frame.screen.x - 80, 32, 32, 32}
	head.save = {global.frame.screen.x - 40, 32, 32, 32}

	head.picker_format = {global.frame.screen.x - 320, 32, 72, 32}
	head.picker_viewer = {global.frame.screen.x - 240, 32, 32, 32}

	head.rectangle_type = {global.frame.screen.x - 280, 32, 72, 32}
	head.rectangle_size = {global.frame.screen.x - 360, 32, 72, 32}

	head.line_size = {global.frame.screen.x - 280, 32, 72, 32}

	head.measure_type = {global.frame.screen.x - 280, 32, 72, 32}
}

@(private = "file")
draw_header :: proc(head: ^Header, global: ^state.State) {
	state.try_reset_message(&global.message)

	raylib.GuiPanel(head.panel, global.message.content)

	raylib.GuiToggle(head.crop, raylib.GuiIconText(.Crop, ""), &global.process.crop)

	raylib.GuiToggle(head.rectangle, raylib.GuiIconText(.Box, ""), &global.process.rectangle)

	raylib.GuiToggle(head.line, raylib.GuiIconText(.Crossline, ""), &global.process.line)

	raylib.GuiToggle(
		head.triangle,
		raylib.GuiIconText(.Cursor_Pointer, ""),
		&global.process.triangle,
	)

	raylib.GuiToggle(head.picker, raylib.GuiIconText(.Color_Picker, ""), &global.process.picker)

	global.process.rotate = raylib.GuiButton(head.rotate, raylib.GuiIconText(.Rotate, ""))

	raylib.GuiToggle(head.measure, raylib.GuiIconText(.Target_Point, ""), &global.process.measure)

	{
		// Keep it disabled if nothing to undo.
		if !state.can_undo_history(&global.history) {
			raylib.GuiSetState(cast(i32)(raylib.Gui_State.Disabled))
		}

		global.process.undo = raylib.GuiButton(head.undo, raylib.GuiIconText(.Undo, ""))

		raylib.GuiSetState(cast(i32)(raylib.Gui_State.Normal)) // Change back to normal
	}

	{
		// Keep it disabled if nothing to redo.
		if !state.can_redo_history(&global.history) {
			raylib.GuiSetState(cast(i32)(raylib.Gui_State.Disabled))
		}

		global.process.redo = raylib.GuiButton(head.redo, raylib.GuiIconText(.Redo, ""))

		raylib.GuiSetState(cast(i32)(raylib.Gui_State.Normal)) // Change back to normal
	}

	global.process.read = raylib.GuiButton(head.read, raylib.GuiIconText(.Zoom_Big, ""))

	global.process.copy = raylib.GuiButton(head.copy, raylib.GuiIconText(.File_Copy, ""))

	global.process.save = raylib.GuiButton(head.save, raylib.GuiIconText(.File_Save, ""))

	process_shortcut(global)

	draw_header_extra(head, global)
	draw_header_hints(head, global)
}

@(private = "file")
draw_header_extra :: proc(head: ^Header, global: ^state.State) {
	switch global.tool {
	case .None:
		return
	case .Crop:
		global.process = {
			crop = global.process.crop,
		}

	case .Rectangle:
		global.process = {
			rectangle = global.process.rectangle,
		}

		raylib.GuiColorPicker(head.color, "Color", &global.rectangle.color)

		raylib.GuiToggle(head.rectangle_type, "No Fill", &global.rectangle.empty)

		if global.rectangle.empty {
			raylib.GuiSlider(head.rectangle_size, "", "", &global.rectangle.width, 2, 32)
		}
	case .Line:
		global.process = {
			line = global.process.line,
		}

		raylib.GuiColorPicker(head.color, "Color", &global.line.color)

		raylib.GuiSlider(head.line_size, "", "", &global.line.width, 2, 32)
	case .Triangle:
		global.process = {
			triangle = global.process.triangle,
		}

		raylib.GuiColorPicker(head.color, "Color", &global.triangle.color)
	case .Picker:
		global.process = {
			picker = global.process.picker,
		}

		if raylib.GuiDropdownBox(
			head.picker_format,
			"HEX;RGB;RGBA",
			&global.picker.select,
			global.picker.active,
		) {
			global.picker.active = !global.picker.active
		}

		raylib.DrawRectangleRec(head.picker_viewer, global.picker.pixel)
	case .Measure:
		global.process = {
			measure = global.process.measure,
		}

		if raylib.GuiDropdownBox(
			head.measure_type,
			"Pixel;Point",
			&global.measure.select,
			global.measure.active,
		) {
			global.measure.active = !global.measure.active
		}
	}
}

@(private = "file")
draw_header_hints :: proc(head: ^Header, global: ^state.State) {
	text_point := global.frame.cursor + {8, 8}
	text_color := get_tip_color(global.config.dark_mode)

	if !global.frame.fly {
		if raylib.CheckCollisionPointRec(global.frame.cursor, head.crop) {
			raylib.DrawTextEx(global.frame.font, "Crop Image", text_point, 16, 0, text_color)
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.rectangle) {
			raylib.DrawTextEx(global.frame.font, "Draw Rectangle", text_point, 16, 0, text_color)
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.line) {
			raylib.DrawTextEx(global.frame.font, "Draw Line", text_point, 16, 0, text_color)
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.triangle) {
			raylib.DrawTextEx(global.frame.font, "Draw Triangle", text_point, 16, 0, text_color)
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.picker) {
			raylib.DrawTextEx(global.frame.font, "Color Picker", text_point, 16, 0, text_color)
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.rotate) {
			raylib.DrawTextEx(global.frame.font, "Rotate Clockwise", text_point, 16, 0, text_color)
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.measure) {
			raylib.DrawTextEx(global.frame.font, "Measure Distance", text_point, 16, 0, text_color)
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.undo) {
			raylib.DrawTextEx(global.frame.font, "Undo Action", text_point, 16, 0, text_color)
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.redo) {
			raylib.DrawTextEx(global.frame.font, "Redo Action", text_point, 16, 0, text_color)
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.read) {
			raylib.DrawTextEx(global.frame.font, "Copy OCR", text_point, 16, 0, text_color)
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.copy) {
			text_point.x -= 80
			raylib.DrawTextEx(global.frame.font, "Copy Image", text_point, 16, 0, text_color)
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.save) {
			text_point.x -= 80
			raylib.DrawTextEx(global.frame.font, "Save Image", text_point, 16, 0, text_color)
		}
	}
}

@(private = "file")
process_shortcut :: proc(global: ^state.State) {
	if raylib.IsKeyDown(.Left_Super) {
		process_super_shortcut(global)
	} else {
		process_raw_shortcut(global)
	}
}

@(private = "file")
process_super_shortcut :: proc(global: ^state.State) {
	shift := raylib.IsKeyDown(.Left_Shift)

	if raylib.IsKeyPressed(.Z) {
		if shift {
			if state.can_redo_history(&global.history) {
				global.process.redo = true
			}
		} else if state.can_undo_history(&global.history) {
			global.process.undo = true
		}
	} else if raylib.IsKeyPressed(.C) {
		global.process.copy = true
	} else if raylib.IsKeyPressed(.S) {
		global.process.save = true
	}
}

@(private = "file")
process_raw_shortcut :: proc(global: ^state.State) {
	if raylib.IsKeyPressed(.C) {
		global.process.crop = !global.process.crop
	} else if raylib.IsKeyPressed(.R) {
		global.process.rectangle = !global.process.rectangle
	} else if raylib.IsKeyPressed(.L) {
		global.process.line = !global.process.line
	} else if raylib.IsKeyPressed(.T) {
		global.process.triangle = !global.process.triangle
	} else if raylib.IsKeyPressed(.I) {
		global.process.picker = !global.process.picker
	} else if raylib.IsKeyPressed(.O) {
		global.process.rotate = true
	} else if raylib.IsKeyPressed(.M) {
		global.process.measure = !global.process.measure
	}
}

@(private = "file", require_results)
process_header :: proc(head: ^Header, global: ^state.State) -> error.Error {
	// Process actions straight away if possible.
	if global.process.rotate {
		tools.rotate(global) or_return
	} else if global.process.undo {
		tools.undo(global) or_return
	} else if global.process.redo {
		tools.redo(global) or_return
	} else if global.process.copy {
		tools.copy(global) or_return
	} else if global.process.read {
		tools.read(global) or_return
	} else if global.process.save {
		tools.save(global, head._allocator) or_return
	}

	switch global.tool {
	case .None:
		if global.process.crop {
			global.tool = .Crop
			state.show_select_area_message(&global.message)
		} else if global.process.rectangle {
			global.tool = .Rectangle
			state.show_create_rectangle_message(&global.message)
		} else if global.process.line {
			global.tool = .Line
			state.show_create_line_message(&global.message)
		} else if global.process.triangle {
			global.tool = .Triangle
			state.show_create_triangle_message(&global.message)
		} else if global.process.picker {
			global.tool = .Picker
			state.show_pick_color_message(&global.message)
		} else if global.process.measure {
			global.tool = .Measure
			state.show_measure_distance_message(&global.message)
		}
	case .Crop:
		if !global.process.crop {
			global.crop = {}
			global.tool = .None
			state.show_idle_message(&global.message)
		}
	case .Rectangle:
		if !global.process.rectangle {
			global.rectangle = {}
			global.tool = .None
			state.show_idle_message(&global.message)
		}
	case .Line:
		if !global.process.line {
			global.line = {}
			global.tool = .None
			state.show_idle_message(&global.message)
		}
	case .Triangle:
		if !global.process.triangle {
			global.triangle = {}
			global.tool = .None
			state.show_idle_message(&global.message)
		}
	case .Picker:
		if !global.process.picker {
			global.picker = {}
			global.tool = .None
			state.show_idle_message(&global.message)
		}
	case .Measure:
		if !global.process.measure {
			global.measure = {}
			global.tool = .None
			state.show_idle_message(&global.message)
		}
	}

	return .None
}
