package window

import "../error"
import "../state"

import "base:runtime"

import "vendor:raylib"

Header :: struct {
	panel_position:    raylib.Rectangle,
	cut_position:      raylib.Rectangle,
	pick_position:     raylib.Rectangle,
	undo_position:     raylib.Rectangle,
	save_position:     raylib.Rectangle,
	reserved_position: raylib.Rectangle,
	_allocator:        runtime.Allocator,
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
load_header :: proc(head: ^Header, global: ^state.State) -> (err: error.Error) {
	layout_header(head, global)

	crop, pick, undo, save := draw_header(head, global)
	process_header_actions(head, global, crop, pick, undo, save) or_return

	return
}

@(private = "file")
layout_header :: proc(head: ^Header, global: ^state.State) {
	head.panel_position = {0, 0, global.frame.screen.x, 72}

	head.cut_position = {8, 32, 32, 32}
	head.pick_position = {48, 32, 32, 32}

	head.undo_position = {global.frame.screen.x - 80, 32, 32, 32}
	head.save_position = {global.frame.screen.x - 40, 32, 32, 32}
	head.reserved_position = {global.frame.screen.x - 120, 32, 32, 32}
}

@(private = "file")
draw_header :: proc(head: ^Header, global: ^state.State) -> (crop, pick, undo, save: bool) {
	raylib.GuiPanel(head.panel_position, "IceShot Toolbar")

	switch global.tool {
	case .None:
		break
	case .Crop:
		crop = true
	case .Pick:
		pick = true
		raylib.DrawRectangleRec(head.reserved_position, global.pick.color)
	}

	raylib.GuiToggle(head.cut_position, raylib.GuiIconText(.ICON_CROP, ""), &crop)

	raylib.GuiToggle(head.pick_position, raylib.GuiIconText(.ICON_COLOR_PICKER, ""), &pick)

	if len(global.history.actions) == 0 {
		raylib.GuiSetState(i32(raylib.GuiState.STATE_DISABLED))
		undo = raylib.GuiButton(head.undo_position, raylib.GuiIconText(.ICON_UNDO, ""))
		raylib.GuiSetState(i32(raylib.GuiState.STATE_NORMAL))
	} else {
		undo = raylib.GuiButton(head.undo_position, raylib.GuiIconText(.ICON_UNDO, ""))
	}

	save = raylib.GuiButton(head.save_position, raylib.GuiIconText(.ICON_FILE_SAVE, ""))

	return
}

@(private = "file")
process_header_actions :: proc(
	head: ^Header,
	global: ^state.State,
	crop, pick, undo, save: bool,
) -> (
	err: error.Error,
) {
	if crop && global.tool == .None {
		global.tool = .Crop
	}

	if pick && global.tool == .None {
		global.tool = .Pick
	}

	if undo {
		process_undo(global) or_return
	}

	if save {
		process_save(global, head._allocator) or_return
	}

	return
}
