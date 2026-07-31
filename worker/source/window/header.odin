package window

import "../action"

import "core:fmt"

import "vendor:raylib"

Header :: struct {
	panel_position: raylib.Rectangle,
	save_position:  raylib.Rectangle,
}

init_header :: proc(gui: ^Window) -> (head: Header, err: action.Action_Error) {
	head.panel_position = {0, 0, 0, 0}
	head.save_position = {8, 32, 32, 32}

	return
}

load_header :: proc(head: ^Header, gui: ^Window) -> (err: action.Action_Error) {
	head.panel_position = {0, 0, gui.render.x, 72}

	raylib.GuiPanel(head.panel_position, "IceShot Toolbar")

	if raylib.GuiButton(head.save_position, raylib.GuiIconText(.ICON_FILE_SAVE, "")) {
		act := action.save_action(gui.viewer.texture) or_return
		defer action.free_action(act)

		fmt.println("Saved to: ", act.path)
	}

	return
}

free_header :: proc(head: ^Header) {

}
