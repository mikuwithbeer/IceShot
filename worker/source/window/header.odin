package window

import "../error"
import "../state"

import "base:runtime"

import "vendor:raylib"

Header :: struct {
	panel_position:     raylib.Rectangle,
	color_position:     raylib.Rectangle,
	crop_position:      raylib.Rectangle,
	rect_position:      raylib.Rectangle,
	pick_position:      raylib.Rectangle,
	undo_position:      raylib.Rectangle,
	copy_position:      raylib.Rectangle,
	save_position:      raylib.Rectangle,
	pick_type_position: raylib.Rectangle,
	pick_view_position: raylib.Rectangle,
	rect_type_position: raylib.Rectangle,
	_allocator:         runtime.Allocator,
}

@(require_results)
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

@(require_results)
load_header :: proc(head: ^Header, global: ^state.State) -> error.Error {
	layout_header(head, global)
	draw_header(head, global)
	process_header_actions(head, global) or_return

	return .None
}

@(private = "file")
layout_header :: proc(head: ^Header, global: ^state.State) {
	head.panel_position = {0, 0, global.frame.screen.x, 72}
	head.color_position = {global.frame.screen.x - 120, 80, 88, 88}

	head.crop_position = {8, 32, 32, 32}
	head.rect_position = {48, 32, 32, 32}
	head.pick_position = {88, 32, 32, 32}

	head.undo_position = {global.frame.screen.x - 120, 32, 32, 32}
	head.copy_position = {global.frame.screen.x - 80, 32, 32, 32}
	head.save_position = {global.frame.screen.x - 40, 32, 32, 32}

	head.pick_type_position = {global.frame.screen.x - 240, 32, 72, 32}
	head.pick_view_position = {global.frame.screen.x - 160, 32, 32, 32}

	head.rect_type_position = {global.frame.screen.x - 200, 32, 72, 32}
}

@(private = "file")
draw_header :: proc(head: ^Header, global: ^state.State) {
	raylib.GuiPanel(head.panel_position, "IceShot Toolbar")

	switch global.tool {
	case .None:
		break
	case .Crop:
		global.process = {
			crop = true,
		}
	case .Rect:
		global.process = {
			rect = true,
		}

		raylib.GuiColorPicker(head.color_position, "Color", &global.rect.color)

		raylib.GuiToggle(head.rect_type_position, "No Fill", &global.rect.empty)
	case .Pick:
		global.process = {
			pick = true,
		}

		if raylib.GuiDropdownBox(
			head.pick_type_position,
			"HEX;RGB;RGBA",
			&global.pick.selected,
			global.pick.dropping,
		) {
			global.pick.dropping = !global.pick.dropping
		}

		raylib.DrawRectangleRec(head.pick_view_position, global.pick.color)
	}

	raylib.GuiToggle(head.crop_position, raylib.GuiIconText(.ICON_CROP, ""), &global.process.crop)

	raylib.GuiToggle(head.rect_position, raylib.GuiIconText(.ICON_BOX, ""), &global.process.rect)

	raylib.GuiToggle(
		head.pick_position,
		raylib.GuiIconText(.ICON_COLOR_PICKER, ""),
		&global.process.pick,
	)

	if len(global.history.actions) == 0 {
		raylib.GuiSetState(i32(raylib.GuiState.STATE_DISABLED))
		global.process.undo = raylib.GuiButton(
			head.undo_position,
			raylib.GuiIconText(.ICON_UNDO, ""),
		)
		raylib.GuiSetState(i32(raylib.GuiState.STATE_NORMAL))
	} else {
		global.process.undo = raylib.GuiButton(
			head.undo_position,
			raylib.GuiIconText(.ICON_UNDO, ""),
		)
	}

	global.process.copy = raylib.GuiButton(
		head.copy_position,
		raylib.GuiIconText(.ICON_FILE_COPY, ""),
	)

	global.process.save = raylib.GuiButton(
		head.save_position,
		raylib.GuiIconText(.ICON_FILE_SAVE, ""),
	)
}

@(private = "file")
process_header_actions :: proc(head: ^Header, global: ^state.State) -> error.Error {
	if global.process.crop && global.tool == .None {
		global.tool = .Crop
	} else if global.process.rect && global.tool == .None {
		global.tool = .Rect
	} else if global.process.pick && global.tool == .None {
		global.tool = .Pick
	} else if global.process.undo {
		process_undo(global) or_return
	} else if global.process.copy {
		process_copy(global) or_return
	} else if global.process.save {
		process_save(global, head._allocator) or_return
	}

	return .None
}
