package window

import "../raylib"

@(private = "file")
BOARD_CELL_SIZE :: 8

@(private = "file")
BOARD_TEXTURE_SIZE :: BOARD_CELL_SIZE * 2

@(private = "file", rodata)
BOARD_COLORS_DARK := [2]raylib.Color{{30, 30, 35, 255}, {40, 40, 45, 255}}

@(private = "file", rodata)
BOARD_COLORS_LIGHT := [2]raylib.Color{{200, 200, 205, 255}, {220, 220, 225, 255}}

@(private)
draw_board :: proc(gui: ^Window) {
	raylib.ClearBackground({255, 255, 255, 255})

	screen: [2]i32 = {i32(gui.state.frame.screen.x), i32(gui.state.frame.screen.y)}
	if screen.x <= 0 || screen.y <= 0 {
		return
	}

	// It is created once and then reused until its size changes.
	if gui.state.frame.tiles.id == 0 {
		pixels: [BOARD_TEXTURE_SIZE * BOARD_TEXTURE_SIZE]raylib.Color

		colors := BOARD_COLORS_LIGHT
		if gui.state.frame.dark {
			colors = BOARD_COLORS_DARK
		}

		for y in 0 ..< BOARD_TEXTURE_SIZE {
			for x in 0 ..< BOARD_TEXTURE_SIZE {
				index := y * BOARD_TEXTURE_SIZE + x
				pixels[index] = colors[(x / BOARD_CELL_SIZE + y / BOARD_CELL_SIZE) % 2]
			}
		}

		image := raylib.Image {
			data    = raw_data(pixels[:]),
			width   = BOARD_TEXTURE_SIZE,
			height  = BOARD_TEXTURE_SIZE,
			mipmaps = 1,
			format  = .Uncompressed_RGBA8888,
		}

		gui.state.frame.tiles = raylib.LoadTextureFromImage(image)

		raylib.SetTextureFilter(gui.state.frame.tiles, .Point)
		raylib.SetTextureWrap(gui.state.frame.tiles, .Repeat)
	}

	source := raylib.Rectangle {
		width  = f32(screen.x),
		height = f32(screen.y),
	}

	target := raylib.Rectangle {
		width  = f32(screen.x),
		height = f32(screen.y),
	}

	raylib.DrawTexturePro(gui.state.frame.tiles, source, target, {}, 0, {255, 255, 255, 255})
}
