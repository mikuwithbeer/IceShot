package raylib

import "core:c"

Gui_State :: enum c.int {
	Normal   = 0,
	Disabled = 3,
}

Gui_Icon_Name :: enum c.int {
	File_Open      = 5,
	File_Save      = 6,
	File_Copy      = 16,
	Cursor_Pointer = 20,
	Color_Picker   = 27,
	Crop           = 36,
	Eye_On         = 44,
	Target_Point   = 48,
	Undo           = 56,
	Redo           = 57,
	Rotate         = 60,
	Box            = 80,
	Zoom_Big       = 105,
	Crossline      = 192,
}

Gui_Control :: enum c.int {
	Default     = 0,
	Button      = 2,
	Toggle      = 3,
	Slider      = 4,
	DropdownBox = 8,
}

Gui_Property :: enum c.int {
	Border_Color            = 0,
	Base_Color_Normal       = 1,
	Text_Color_Normal       = 2,
	Border_Color_Focused    = 3,
	Base_Color_Focused      = 4,
	Text_Color_Focused      = 5,
	Border_Color_Pressed    = 6,
	Base_Color_Pressed      = 7,
	Text_Color_Pressed      = 8,
	Border_Color_Disabled   = 9,
	Base_Color_Disabled     = 10,
	Text_Color_Disabled     = 11,
	Border_Width            = 12,
	Dropdown_Text_Padding   = 13,
	Dropdown_Text_Alignment = 14,
	Text_Padding            = 16,
	Text_Inner_Padding      = 17,
	Line_Color              = 18,
	Background_Color        = 19,
	Text_Alignment          = 20,
}

foreign import raygui "../../assets/raylib/libraygui.a"

@(default_calling_convention = "c", require_results)
foreign raygui {
	GuiSetFont :: proc(font: Font) ---
	GuiSetState :: proc(state: c.int) ---
	GuiSetStyle :: proc(control: Gui_Control, property: Gui_Property, value: c.int) ---

	GuiIconText :: proc(icon_id: Gui_Icon_Name, text: cstring) -> cstring ---

	GuiButton :: proc(bounds: Rectangle, text: cstring) -> c.bool ---
	GuiColorPicker :: proc(bounds: Rectangle, text: cstring, selected_color: ^Color) -> c.int ---
	GuiDropdownBox :: proc(bounds: Rectangle, text: cstring, active_index: ^c.int, is_edit_mode: c.bool) -> c.bool ---
	GuiPanel :: proc(bounds: Rectangle, text: cstring) -> c.int ---
	GuiSlider :: proc(bounds: Rectangle, left_text, right_text: cstring, current_value: ^f32, minimum_value, maximum_value: f32) -> c.int ---
	GuiToggle :: proc(bounds: Rectangle, text: cstring, is_active: ^c.bool) -> c.int ---
}
