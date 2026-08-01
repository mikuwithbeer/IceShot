package window

import "vendor:raylib"

BOARD_CELL_SIZE :: 8

draw_board :: proc(gui: ^Window) {
	render: [2]i32 = {i32(gui.state.frame.render.x), i32(gui.state.frame.render.y)}
	if render.x <= 0 || render.y <= 0 {
		raylib.ClearBackground({255, 255, 255, 255})
		return
	}

	if gui.state.frame.board {
		if gui.state.frame.tiles.id != 0 {
			raylib.UnloadRenderTexture(gui.state.frame.tiles)
		}

		gui.state.frame.tiles = raylib.LoadRenderTexture(render.x, render.y)

		raylib.BeginTextureMode(gui.state.frame.tiles)
		raylib.ClearBackground({255, 255, 255, 255})

		columns := render.x / BOARD_CELL_SIZE + 1
		rows := render.y / BOARD_CELL_SIZE + 1

		colors := [2]raylib.Color{{30, 30, 35, 255}, {40, 40, 45, 255}}

		for column in 0 ..< columns {
			for row in 0 ..< rows {
				color := colors[(column + row) % 2]
				raylib.DrawRectangle(
					column * BOARD_CELL_SIZE,
					row * BOARD_CELL_SIZE,
					BOARD_CELL_SIZE,
					BOARD_CELL_SIZE,
					color,
				)
			}
		}

		raylib.EndTextureMode()
		gui.state.frame.board = false
	}

	raylib.ClearBackground({255, 255, 255, 255})

	source := raylib.Rectangle{0, 0, f32(render.x), -f32(render.y)}
	target := raylib.Rectangle{0, 0, f32(render.x), f32(render.y)}

	raylib.DrawTexturePro(
		gui.state.frame.tiles.texture,
		source,
		target,
		{0, 0},
		0.0,
		{255, 255, 255, 255},
	)
}
