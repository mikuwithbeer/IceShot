package window

import "../error"
import "../state"

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
	global: ^state.State,
	allocator := context.allocator,
) -> (
	head: Header,
	err: error.Error,
) {
	head._allocator = allocator

	head.panel_position = {0, 0, 0, 0}
	head.cut_position = {8, 32, 32, 32}

	head.undo_position = {0, 0, 32, 32}
	head.save_position = {0, 0, 32, 32}

	return
}

@(require_results)
load_header :: proc(head: ^Header, global: ^state.State) -> (err: error.Error) {
	head.panel_position = {0, 0, global.frame.screen.x, 72}

	head.save_position = {global.frame.screen.x - 40, 32, 32, 32}
	head.undo_position = {global.frame.screen.x - 80, 32, 32, 32}

	raylib.GuiPanel(head.panel_position, "IceShot Toolbar")

	if raylib.GuiButton(head.save_position, raylib.GuiIconText(.ICON_FILE_SAVE, "")) {
		effect_save(global, head._allocator) or_return
	}

	raylib.GuiToggle(head.cut_position, raylib.GuiIconText(.ICON_CROP, ""), &global.crop.running)

	if len(global.history.actions) == 0 {
		raylib.GuiSetState(i32(raylib.GuiState.STATE_DISABLED))
	}

	if raylib.GuiButton(head.undo_position, raylib.GuiIconText(.ICON_UNDO, "")) {
		effect_undo(global) or_return
	}

	raylib.GuiSetState(i32(raylib.GuiState.STATE_NORMAL))

	return
}
