package window

import "../error"
import "../state"

import "base:runtime"

import "vendor:raylib"

Header :: struct {
	panel:      raylib.Rectangle,
	color:      raylib.Rectangle,
	crop:       raylib.Rectangle,
	rect:       raylib.Rectangle,
	pick:       raylib.Rectangle,
	undo:       raylib.Rectangle,
	read:       raylib.Rectangle,
	copy:       raylib.Rectangle,
	save:       raylib.Rectangle,
	pick_type:  raylib.Rectangle,
	pick_view:  raylib.Rectangle,
	rect_type:  raylib.Rectangle,
	_allocator: runtime.Allocator,
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
	head.panel = {0, 0, global.frame.screen.x, 72}
	head.color = {global.frame.screen.x - 120, 80, 88, 88}

	head.crop = {8, 32, 32, 32}
	head.rect = {48, 32, 32, 32}
	head.pick = {88, 32, 32, 32}

	head.undo = {global.frame.screen.x - 160, 32, 32, 32}
	head.read = {global.frame.screen.x - 120, 32, 32, 32}
	head.copy = {global.frame.screen.x - 80, 32, 32, 32}
	head.save = {global.frame.screen.x - 40, 32, 32, 32}

	head.pick_type = {global.frame.screen.x - 280, 32, 72, 32}
	head.pick_view = {global.frame.screen.x - 200, 32, 32, 32}

	head.rect_type = {global.frame.screen.x - 240, 32, 72, 32}
}

@(private = "file")
draw_header :: proc(head: ^Header, global: ^state.State) {
	raylib.GuiPanel(head.panel, "IceShot Toolbar")

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

		raylib.GuiColorPicker(head.color, "Color", &global.rect.color)

		raylib.GuiToggle(head.rect_type, "No Fill", &global.rect.empty)
	case .Pick:
		global.process = {
			pick = true,
		}

		if raylib.GuiDropdownBox(
			head.pick_type,
			"HEX;RGB;RGBA",
			&global.pick.selected,
			global.pick.dropping,
		) {
			global.pick.dropping = !global.pick.dropping
		}

		raylib.DrawRectangleRec(head.pick_view, global.pick.color)
	}

	raylib.GuiToggle(head.crop, raylib.GuiIconText(.ICON_CROP, ""), &global.process.crop)

	raylib.GuiToggle(head.rect, raylib.GuiIconText(.ICON_BOX, ""), &global.process.rect)

	raylib.GuiToggle(head.pick, raylib.GuiIconText(.ICON_COLOR_PICKER, ""), &global.process.pick)

	if len(global.history.actions) == 0 {
		raylib.GuiSetState(i32(raylib.GuiState.STATE_DISABLED))
		global.process.undo = raylib.GuiButton(head.undo, raylib.GuiIconText(.ICON_UNDO, ""))
		raylib.GuiSetState(i32(raylib.GuiState.STATE_NORMAL))
	} else {
		global.process.undo = raylib.GuiButton(head.undo, raylib.GuiIconText(.ICON_UNDO, ""))
	}

	global.process.read = raylib.GuiButton(head.read, raylib.GuiIconText(.ICON_ZOOM_BIG, ""))

	global.process.copy = raylib.GuiButton(head.copy, raylib.GuiIconText(.ICON_FILE_COPY, ""))

	global.process.save = raylib.GuiButton(head.save, raylib.GuiIconText(.ICON_FILE_SAVE, ""))
}

@(private = "file")
process_header_actions :: proc(head: ^Header, global: ^state.State) -> error.Error {
	if global.process.undo {
		process_undo(global) or_return
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
		} else if global.process.rect {
			global.tool = .Rect
		} else if global.process.pick {
			global.tool = .Pick
		}
	case .Crop:
		if !global.process.crop {
			global.crop = {}
			global.tool = .None
		}
	case .Rect:
		if !global.process.rect {
			global.rect = {}
			global.tool = .None
		}
	case .Pick:
		if !global.process.pick {
			global.pick = {}
			global.tool = .None
		}
	}

	return .None
}
