package window

import "../error"
import "../state"

import "base:runtime"

import "vendor:raylib"

Header :: struct {
	panel:          raylib.Rectangle,
	color:          raylib.Rectangle,
	crop:           raylib.Rectangle,
	rect:           raylib.Rectangle,
	line:           raylib.Rectangle,
	tria:           raylib.Rectangle,
	pick:           raylib.Rectangle,
	rotc:           raylib.Rectangle,
	rule:           raylib.Rectangle,
	undo:           raylib.Rectangle,
	redo:           raylib.Rectangle,
	read:           raylib.Rectangle,
	copy:           raylib.Rectangle,
	save:           raylib.Rectangle,
	pick_type:      raylib.Rectangle,
	pick_view:      raylib.Rectangle,
	rect_type:      raylib.Rectangle,
	rect_thickness: raylib.Rectangle,
	line_thickness: raylib.Rectangle,
	rule_type:      raylib.Rectangle,
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
	head.rect = {48, 32, 32, 32}
	head.line = {88, 32, 32, 32}
	head.tria = {128, 32, 32, 32}
	head.pick = {168, 32, 32, 32}
	head.rotc = {208, 32, 32, 32}
	head.rule = {248, 32, 32, 32}

	head.undo = {global.frame.screen.x - 200, 32, 32, 32}
	head.redo = {global.frame.screen.x - 160, 32, 32, 32}
	head.read = {global.frame.screen.x - 120, 32, 32, 32}
	head.copy = {global.frame.screen.x - 80, 32, 32, 32}
	head.save = {global.frame.screen.x - 40, 32, 32, 32}

	head.pick_type = {global.frame.screen.x - 320, 32, 72, 32}
	head.pick_view = {global.frame.screen.x - 240, 32, 32, 32}

	head.rect_type = {global.frame.screen.x - 280, 32, 72, 32}
	head.rect_thickness = {global.frame.screen.x - 360, 32, 72, 32}
	head.line_thickness = {global.frame.screen.x - 280, 32, 72, 32}

	head.rule_type = {global.frame.screen.x - 280, 32, 72, 32}
}

@(private = "file")
draw_header :: proc(head: ^Header, global: ^state.State) {
	state.try_reset_message(&global.message)

	raylib.GuiPanel(head.panel, global.message.content)

	raylib.GuiToggle(head.crop, raylib.GuiIconText(.ICON_CROP, ""), &global.process.crop)

	raylib.GuiToggle(head.rect, raylib.GuiIconText(.ICON_BOX, ""), &global.process.rect)

	raylib.GuiToggle(head.line, raylib.GuiIconText(.ICON_CROSSLINE, ""), &global.process.line)

	raylib.GuiToggle(head.tria, raylib.GuiIconText(.ICON_CURSOR_POINTER, ""), &global.process.tria)

	raylib.GuiToggle(head.pick, raylib.GuiIconText(.ICON_COLOR_PICKER, ""), &global.process.pick)

	global.process.rotc = raylib.GuiButton(head.rotc, raylib.GuiIconText(.ICON_ROTATE, ""))

	raylib.GuiToggle(head.rule, raylib.GuiIconText(.ICON_TARGET_POINT, ""), &global.process.rule)

	// Keep it disabled if nothing to undo.
	if !state.can_undo_history(&global.history) {
		raylib.GuiSetState(i32(raylib.GuiState.STATE_DISABLED))
	}

	global.process.undo = raylib.GuiButton(head.undo, raylib.GuiIconText(.ICON_UNDO, ""))

	raylib.GuiSetState(i32(raylib.GuiState.STATE_NORMAL)) // Change back to normal

	// Keep it disabled if nothing to redo.
	if !state.can_redo_history(&global.history) {
		raylib.GuiSetState(i32(raylib.GuiState.STATE_DISABLED))
	}

	global.process.redo = raylib.GuiButton(head.redo, raylib.GuiIconText(.ICON_REDO, ""))

	raylib.GuiSetState(i32(raylib.GuiState.STATE_NORMAL)) // Change back to normal

	global.process.read = raylib.GuiButton(head.read, raylib.GuiIconText(.ICON_ZOOM_BIG, ""))

	global.process.copy = raylib.GuiButton(head.copy, raylib.GuiIconText(.ICON_FILE_COPY, ""))

	global.process.save = raylib.GuiButton(head.save, raylib.GuiIconText(.ICON_FILE_SAVE, ""))

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

	case .Rect:
		global.process = {
			rect = global.process.rect,
		}

		raylib.GuiColorPicker(head.color, "Color", &global.rect.color)

		raylib.GuiToggle(head.rect_type, "No Fill", &global.rect.empty)

		if global.rect.empty {
			raylib.GuiSlider(head.rect_thickness, "", "", &global.rect.width, 2, 32)
		}
	case .Line:
		global.process = {
			line = global.process.line,
		}

		raylib.GuiColorPicker(head.color, "Color", &global.line.color)

		raylib.GuiSlider(head.line_thickness, "", "", &global.line.width, 2, 32)
	case .Tria:
		global.process = {
			tria = global.process.tria,
		}

		raylib.GuiColorPicker(head.color, "Color", &global.tria.color)
	case .Pick:
		global.process = {
			pick = global.process.pick,
		}

		if raylib.GuiDropdownBox(
			head.pick_type,
			"HEX;RGB;RGBA",
			&global.pick.select,
			global.pick.active,
		) {
			global.pick.active = !global.pick.active
		}

		raylib.DrawRectangleRec(head.pick_view, global.pick.pixel)
	case .Rule:
		global.process = {
			rule = global.process.rule,
		}

		if raylib.GuiDropdownBox(
			head.rule_type,
			"Pixel;Point",
			&global.rule.select,
			global.rule.active,
		) {
			global.rule.active = !global.rule.active
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
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.rect) {
			raylib.DrawTextEx(global.frame.font, "Draw Rectangle", text_point, 16, 0, text_color)
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.line) {
			raylib.DrawTextEx(global.frame.font, "Draw Line", text_point, 16, 0, text_color)
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.tria) {
			raylib.DrawTextEx(global.frame.font, "Draw Triangle", text_point, 16, 0, text_color)
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.pick) {
			raylib.DrawTextEx(global.frame.font, "Color Picker", text_point, 16, 0, text_color)
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.rotc) {
			raylib.DrawTextEx(global.frame.font, "Rotate Clockwise", text_point, 16, 0, text_color)
		} else if raylib.CheckCollisionPointRec(global.frame.cursor, head.rule) {
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
	if raylib.IsKeyDown(.LEFT_SUPER) {
		process_super_shortcut(global)
	} else {
		process_raw_shortcut(global)
	}
}

@(private = "file")
process_super_shortcut :: proc(global: ^state.State) {
	shift := raylib.IsKeyDown(.LEFT_SHIFT)

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
		global.process.rect = !global.process.rect
	} else if raylib.IsKeyPressed(.L) {
		global.process.line = !global.process.line
	} else if raylib.IsKeyPressed(.T) {
		global.process.tria = !global.process.tria
	} else if raylib.IsKeyPressed(.I) {
		global.process.pick = !global.process.pick
	} else if raylib.IsKeyPressed(.O) {
		global.process.rotc = true
	} else if raylib.IsKeyPressed(.M) {
		global.process.rule = !global.process.rule
	}
}

@(private = "file", require_results)
process_header :: proc(head: ^Header, global: ^state.State) -> error.Error {
	// Process actions straight away if possible.
	if global.process.rotc {
		process_rotc(global) or_return
	} else if global.process.undo {
		process_undo(global) or_return
	} else if global.process.redo {
		process_redo(global) or_return
	} else if global.process.copy {
		process_copy(global) or_return
	} else if global.process.read {
		process_read(global) or_return
	} else if global.process.save {
		process_save(global, head._allocator) or_return
	}

	switch global.tool {
	case .None:
		if global.process.crop {
			global.tool = .Crop
			state.show_select_area_message(&global.message)
		} else if global.process.rect {
			global.tool = .Rect
			state.show_create_rectangle_message(&global.message)
		} else if global.process.line {
			global.tool = .Line
			state.show_create_line_message(&global.message)
		} else if global.process.tria {
			global.tool = .Tria
			state.show_create_triangle_message(&global.message) // TODO update that
		} else if global.process.pick {
			global.tool = .Pick
			state.show_pick_color_message(&global.message)
		} else if global.process.rule {
			global.tool = .Rule
			state.show_measure_distance_message(&global.message)
		}
	case .Crop:
		if !global.process.crop {
			global.crop = {}
			global.tool = .None
			state.show_idle_message(&global.message)
		}
	case .Rect:
		if !global.process.rect {
			global.rect = {}
			global.tool = .None
			state.show_idle_message(&global.message)
		}
	case .Line:
		if !global.process.line {
			global.line = {}
			global.tool = .None
			state.show_idle_message(&global.message)
		}
	case .Tria:
		if !global.process.tria {
			global.tria = {}
			global.tool = .None
			state.show_idle_message(&global.message)
		}
	case .Pick:
		if !global.process.pick {
			global.pick = {}
			global.tool = .None
			state.show_idle_message(&global.message)
		}
	case .Rule:
		if !global.process.rule {
			global.rule = {}
			global.tool = .None
			state.show_idle_message(&global.message)
		}
	}

	return .None
}
