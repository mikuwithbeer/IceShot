package window

import "../raylib"
import "../state"

@(private = "file")
STYLE_FONT_DATA :: #load("../../assets/fonts/IntelOneMono.ttf")

@(require_results)
get_brand_color :: proc(dark: bool) -> (raylib.Color, raylib.Color) {
	if dark {
		return {121, 191, 255, 255}, {121, 191, 255, 55}
	} else {
		return {9, 95, 255, 255}, {9, 95, 255, 105}
	}
}

@(require_results)
get_tip_color :: proc(dark: bool) -> raylib.Color {
	if dark {
		return {255, 255, 255, 255}
	} else {
		return {0, 0, 0, 255}
	}
}

@(private)
init_dark_mode :: proc(frame: ^state.Frame) {
	if frame.style {
		return
	} else {
		frame.style = true
	}

	raylib.GuiSetStyle(.Default, .Border_Color, 0x2C2C2CFF)
	raylib.GuiSetStyle(.Default, .Base_Color_Normal, 0x1C1C1CFF)
	raylib.GuiSetStyle(.Default, .Text_Color_Normal, transmute(i32)u32(0x999999FF))

	raylib.GuiSetStyle(.Default, .Border_Color_Focused, 0x2C2C2CFF)
	raylib.GuiSetStyle(.Default, .Base_Color_Focused, 0x2C2C2CFF)
	raylib.GuiSetStyle(.Default, .Text_Color_Focused, 0x79BFFFFF)

	raylib.GuiSetStyle(.Default, .Border_Color_Pressed, 0x2C2C2CFF)
	raylib.GuiSetStyle(.Default, .Base_Color_Pressed, 0x1C1C1CFF)
	raylib.GuiSetStyle(.Default, .Text_Color_Pressed, 0x79BFFFFF)

	raylib.GuiSetStyle(.Default, .Border_Color_Disabled, 0x2C2C2CFF)
	raylib.GuiSetStyle(.Default, .Base_Color_Disabled, 0x1C1C1CFF)
	raylib.GuiSetStyle(.Default, .Text_Color_Disabled, 0x333333FF)

	raylib.GuiSetStyle(.Default, .Line_Color, 0x2C2C2CFF)
	raylib.GuiSetStyle(.Default, .Background_Color, 0x1C1C1CFF)

	raylib.GuiSetStyle(.Slider, .Base_Color_Pressed, 0x79BFFFFF)

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

	raylib.GuiSetStyle(.Default, .Border_Color, transmute(i32)u32(0xD3D3D3FF))
	raylib.GuiSetStyle(.Default, .Base_Color_Normal, transmute(i32)u32(0xF3F3F3FF))
	raylib.GuiSetStyle(.Default, .Text_Color_Normal, 0x333333FF)

	raylib.GuiSetStyle(.Default, .Border_Color_Focused, transmute(i32)u32(0xD3D3D3FF))
	raylib.GuiSetStyle(.Default, .Base_Color_Focused, transmute(i32)u32(0xD3D3D3FF))
	raylib.GuiSetStyle(.Default, .Text_Color_Focused, 0x095FFFFF)

	raylib.GuiSetStyle(.Default, .Border_Color_Pressed, transmute(i32)u32(0xD3D3D3FF))
	raylib.GuiSetStyle(.Default, .Base_Color_Pressed, transmute(i32)u32(0xF3F3F3FF))
	raylib.GuiSetStyle(.Default, .Text_Color_Pressed, 0x095FFFFF)

	raylib.GuiSetStyle(.Default, .Border_Color_Disabled, transmute(i32)u32(0xD3D3D3FF))
	raylib.GuiSetStyle(.Default, .Base_Color_Disabled, transmute(i32)u32(0xF3F3F3FF))
	raylib.GuiSetStyle(.Default, .Text_Color_Disabled, transmute(i32)u32(0x999999FF))

	raylib.GuiSetStyle(.Default, .Line_Color, transmute(i32)u32(0xD3D3D3FF))
	raylib.GuiSetStyle(.Default, .Background_Color, transmute(i32)u32(0xF3F3F3FF))

	raylib.GuiSetStyle(.Slider, .Base_Color_Pressed, 0x095FFFFF)

	init_layout(frame)
	init_font(frame)
}

@(private = "file")
init_layout :: proc(frame: ^state.Frame) {
	raylib.GuiSetStyle(.Default, .Text_Padding, 0x00000012)
	raylib.GuiSetStyle(.Default, .Text_Inner_Padding, 0x00000000)
	raylib.GuiSetStyle(.Default, .Text_Alignment, 0x00000018)

	raylib.GuiSetStyle(.Button, .Border_Width, 0x00000001)

	raylib.GuiSetStyle(.DropdownBox, .Dropdown_Text_Padding, 0x00000008)
	raylib.GuiSetStyle(.DropdownBox, .Dropdown_Text_Alignment, 0x00000000)
}

@(private = "file")
init_font :: proc(frame: ^state.Frame) {
	font := raylib.LoadFontFromMemory(
		".ttf",
		raw_data(STYLE_FONT_DATA),
		i32(len(STYLE_FONT_DATA)),
		64, // Supersampling to increase quality
		nil,
		0,
	)

	raylib.SetTextureFilter(font.texture, .BiLinear)
	raylib.GuiSetFont(font)

	frame.font = font
}
