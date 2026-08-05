package tools

import "../state"

import "vendor:raylib"

replace_current_texture :: proc(global: ^state.State, texture: raylib.Texture2D) {
	// Keep the initial texture for history replay.
	if global.frame.current.id != global.frame.initial.id {
		raylib.UnloadTexture(global.frame.current)
	}

	global.frame.current = texture
}
