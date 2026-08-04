package window

import "../state"

import "vendor:raylib"

@(private = "file")
STYLE_FONT_DATA :: #load("../../assets/fonts/IntelOneMono.ttf")

@(private = "file")
STYLE_BRAND_COLOR_DARK :: raylib.Color{121, 191, 255, 255}

@(private = "file")
STYLE_BRAND_COLOR_LIGHT :: raylib.Color{9, 95, 255, 255}

@(require_results)
get_brand_color :: proc(dark: bool) -> (raylib.Color, raylib.Color) {
	if dark {
		return STYLE_BRAND_COLOR_DARK, STYLE_BRAND_COLOR_DARK - {0, 0, 0, 200}
	} else {
		return STYLE_BRAND_COLOR_LIGHT, STYLE_BRAND_COLOR_LIGHT - {0, 0, 0, 150}
	}
}

@(private = "file")
STYLE_TIP_COLOR_DARK :: raylib.WHITE

@(private = "file")
STYLE_TIP_COLOR_LIGHT :: raylib.BLACK

@(require_results)
get_tip_color :: proc(dark: bool) -> raylib.Color {
	if dark {
		return STYLE_TIP_COLOR_DARK
	} else {
		return STYLE_TIP_COLOR_LIGHT
	}
}

STYLE_BORDER_COLOR :: 0
STYLE_BASE_COLOR_NORMAL :: 1
STYLE_TEXT_COLOR_NORMAL :: 2
STYLE_BORDER_COLOR_FOCUSED :: 3
STYLE_BASE_COLOR_FOCUSED :: 4
STYLE_TEXT_COLOR_FOCUSED :: 5
STYLE_BORDER_COLOR_PRESSED :: 6
STYLE_BASE_COLOR_PRESSED :: 7
STYLE_TEXT_COLOR_PRESSED :: 8
STYLE_BORDER_COLOR_DISABLED :: 9
STYLE_BASE_COLOR_DISABLED :: 10
STYLE_TEXT_COLOR_DISABLED :: 11
STYLE_BORDER_WIDTH :: 12
STYLE_DROPDOWN_TEXT_PADDING :: 13
STYLE_DROPDOWN_TEXT_ALIGNMENT :: 14
STYLE_TEXT_PADDING :: 16
STYLE_TEXT_INNER_PADDING :: 17
STYLE_LINE_COLOR :: 18
STYLE_BACKGROUND_COLOR :: 19
STYLE_TEXT_ALIGNMENT :: 20

@(private)
init_dark_mode :: proc(frame: ^state.Frame) {
	if frame.style {
		return
	} else {
		frame.style = true
	}

	raylib.GuiSetStyle(.DEFAULT, STYLE_BORDER_COLOR, 0x2C2C2CFF)
	raylib.GuiSetStyle(.DEFAULT, STYLE_BASE_COLOR_NORMAL, 0x1C1C1CFF)
	raylib.GuiSetStyle(.DEFAULT, STYLE_TEXT_COLOR_NORMAL, transmute(i32)u32(0x999999FF))

	raylib.GuiSetStyle(.DEFAULT, STYLE_BORDER_COLOR_FOCUSED, 0x2C2C2CFF)
	raylib.GuiSetStyle(.DEFAULT, STYLE_BASE_COLOR_FOCUSED, 0x2C2C2CFF)
	raylib.GuiSetStyle(.DEFAULT, STYLE_TEXT_COLOR_FOCUSED, 0x79BFFFFF)

	raylib.GuiSetStyle(.DEFAULT, STYLE_BORDER_COLOR_PRESSED, 0x2C2C2CFF)
	raylib.GuiSetStyle(.DEFAULT, STYLE_BASE_COLOR_PRESSED, 0x1C1C1CFF)
	raylib.GuiSetStyle(.DEFAULT, STYLE_TEXT_COLOR_PRESSED, 0x79BFFFFF)

	raylib.GuiSetStyle(.DEFAULT, STYLE_BORDER_COLOR_DISABLED, 0x2C2C2CFF)
	raylib.GuiSetStyle(.DEFAULT, STYLE_BASE_COLOR_DISABLED, 0x1C1C1CFF)
	raylib.GuiSetStyle(.DEFAULT, STYLE_TEXT_COLOR_DISABLED, 0x333333FF)

	raylib.GuiSetStyle(.DEFAULT, STYLE_LINE_COLOR, 0x2C2C2CFF)
	raylib.GuiSetStyle(.DEFAULT, STYLE_BACKGROUND_COLOR, 0x1C1C1CFF)

	raylib.GuiSetStyle(.SLIDER, STYLE_BASE_COLOR_PRESSED, 0x79BFFFFF)

	init_layout(frame)
	init_font(frame)
}

@(private)
init_light_mode :: proc(frame: ^state.Frame) {
	if frame.style {
		return
	} else {
		frame.style = true
	}

	raylib.GuiSetStyle(.DEFAULT, STYLE_BORDER_COLOR, transmute(i32)u32(0xD3D3D3FF))
	raylib.GuiSetStyle(.DEFAULT, STYLE_BASE_COLOR_NORMAL, transmute(i32)u32(0xF3F3F3FF))
	raylib.GuiSetStyle(.DEFAULT, STYLE_TEXT_COLOR_NORMAL, 0x333333FF)

	raylib.GuiSetStyle(.DEFAULT, STYLE_BORDER_COLOR_FOCUSED, transmute(i32)u32(0xD3D3D3FF))
	raylib.GuiSetStyle(.DEFAULT, STYLE_BASE_COLOR_FOCUSED, transmute(i32)u32(0xD3D3D3FF))
	raylib.GuiSetStyle(.DEFAULT, STYLE_TEXT_COLOR_FOCUSED, 0x095FFFFF)

	raylib.GuiSetStyle(.DEFAULT, STYLE_BORDER_COLOR_PRESSED, transmute(i32)u32(0xD3D3D3FF))
	raylib.GuiSetStyle(.DEFAULT, STYLE_BASE_COLOR_PRESSED, transmute(i32)u32(0xF3F3F3FF))
	raylib.GuiSetStyle(.DEFAULT, STYLE_TEXT_COLOR_PRESSED, 0x095FFFFF)

	raylib.GuiSetStyle(.DEFAULT, STYLE_BORDER_COLOR_DISABLED, transmute(i32)u32(0xD3D3D3FF))
	raylib.GuiSetStyle(.DEFAULT, STYLE_BASE_COLOR_DISABLED, transmute(i32)u32(0xF3F3F3FF))
	raylib.GuiSetStyle(.DEFAULT, STYLE_TEXT_COLOR_DISABLED, transmute(i32)u32(0x999999FF))

	raylib.GuiSetStyle(.DEFAULT, STYLE_LINE_COLOR, transmute(i32)u32(0xD3D3D3FF))
	raylib.GuiSetStyle(.DEFAULT, STYLE_BACKGROUND_COLOR, transmute(i32)u32(0xF3F3F3FF))

	raylib.GuiSetStyle(.SLIDER, STYLE_BASE_COLOR_PRESSED, 0x095FFFFF)

	init_layout(frame)
	init_font(frame)
}

@(private = "file")
init_layout :: proc(frame: ^state.Frame) {
	raylib.GuiSetStyle(.DEFAULT, STYLE_TEXT_PADDING, 0x00000012)
	raylib.GuiSetStyle(.DEFAULT, STYLE_TEXT_INNER_PADDING, 0x00000000)
	raylib.GuiSetStyle(.DEFAULT, STYLE_TEXT_ALIGNMENT, 0x00000018)

	raylib.GuiSetStyle(.BUTTON, STYLE_BORDER_WIDTH, 0x00000001)

	raylib.GuiSetStyle(.DROPDOWNBOX, STYLE_DROPDOWN_TEXT_PADDING, 0x00000008)
	raylib.GuiSetStyle(.DROPDOWNBOX, STYLE_DROPDOWN_TEXT_ALIGNMENT, 0x00000000)
}

@(private = "file")
init_font :: proc(frame: ^state.Frame) {
	font := raylib.LoadFontFromMemory(
		".ttf",
		raw_data(STYLE_FONT_DATA),
		i32(len(STYLE_FONT_DATA)),
		64,
		nil,
		0,
	)

	raylib.SetTextureFilter(font.texture, .BILINEAR)
	raylib.GuiSetFont(font)

	frame.font = font
}
