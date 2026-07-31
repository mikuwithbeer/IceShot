package window

import "core:fmt"

import "vendor:raylib"

Header :: struct {
	panel_position: raylib.Rectangle,
	save_position:  raylib.Rectangle,
}

init_header :: proc(gui: ^Window) -> (head: Header, ok: bool) {
	head.panel_position = {0, 0, 0, 0}
	head.save_position = {8, 32, 80, 32}

	ok = true
	return
}

load_header :: proc(head: ^Header, gui: ^Window) -> (ok: bool) {
	head.panel_position = {0, 0, gui.render.x, 72}

	raylib.GuiPanel(head.panel_position, "IceShot Toolbar")

	if raylib.GuiButton(head.save_position, raylib.GuiIconText(.ICON_FOLDER_SAVE, "Save")) {
		fmt.println("TODO")
	}

	ok = true
	return
}

free_header :: proc(head: ^Header) {}
