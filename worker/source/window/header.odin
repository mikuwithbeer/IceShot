package window

import "../action"
import "../manage"

import "base:runtime"

import "vendor:raylib"

Header :: struct {
	panel_position: raylib.Rectangle,
	cut_position:   raylib.Rectangle,
	undo_position:  raylib.Rectangle,
	save_position:  raylib.Rectangle,
	_allocator:     runtime.Allocator,
}

@(require_results)
init_header :: proc(
	manager: ^manage.Manage,
	allocator := context.allocator,
) -> (
	head: Header,
	err: action.Action_Error,
) {
	head._allocator = allocator

	head.panel_position = {0, 0, 0, 0}
	head.cut_position = {8, 32, 32, 32}

	head.undo_position = {0, 0, 32, 32}
	head.save_position = {0, 0, 32, 32}

	return
}

@(require_results)
load_header :: proc(head: ^Header, manager: ^manage.Manage) -> (err: action.Action_Error) {
	head.panel_position = {0, 0, manager.frame.screen.x, 72}

	head.save_position = {manager.frame.screen.x - 40, 32, 32, 32}
	head.undo_position = {manager.frame.screen.x - 80, 32, 32, 32}

	raylib.GuiPanel(head.panel_position, "IceShot Toolbar")

	if raylib.GuiButton(head.save_position, raylib.GuiIconText(.ICON_FILE_SAVE, "")) {
		act := action.save_action(manager.frame.shot, head._allocator) or_return
		action.free_action(act, head._allocator)
	}

	raylib.GuiToggle(head.cut_position, raylib.GuiIconText(.ICON_CROP, ""), &manager.crop.running)

	if len(manager.history.shots) == 0 {
		raylib.GuiSetState(i32(raylib.GuiState.STATE_DISABLED))
	}

	if raylib.GuiButton(head.undo_position, raylib.GuiIconText(.ICON_UNDO, "")) {
		texture, _ := manage.pop_history(&manager.history)
		manager.frame.shot = texture
	}

	raylib.GuiSetState(i32(raylib.GuiState.STATE_NORMAL))

	return
}
