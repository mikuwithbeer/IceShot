package raylib

import "core:c"

Vector2 :: [2]f32

Color :: distinct [4]u8

Rectangle :: struct {
	x, y:          f32,
	width, height: f32,
}

Config_Flag :: enum c.int {
	VSync_Hint = 6,
	Resizable  = 2,
	HighDPI    = 13,
}

Config_Flags :: distinct bit_set[Config_Flag;c.int]

Mouse_Button :: enum c.int {
	Left   = 0,
	Right  = 1,
	Middle = 2,
}

Keyboard_Key :: enum c.int {
	None        = 0,
	Space       = 32,
	A           = 65,
	C           = 67,
	D           = 68,
	I           = 73,
	L           = 76,
	M           = 77,
	O           = 79,
	R           = 82,
	S           = 83,
	T           = 84,
	U           = 85,
	V           = 86,
	W           = 87,
	Z           = 90,
	Right       = 262,
	Left        = 263,
	Down        = 264,
	Up          = 265,
	Left_Shift  = 340,
	Left_Super  = 343,
	Right_Shift = 344,
	Right_Super = 347,
}

Pixel_Format :: enum c.int {
	Uncompressed_Grayscale = 1,
	Uncompressed_RGBA8888  = 7,
}

Texture_Filter :: enum c.int {
	Point = 0,
	BiLinear,
}

Texture_Wrap :: enum c.int {
	Repeat = 0,
	Clamp,
}

Image :: struct {
	data:          rawptr,
	width, height: c.int,
	mipmaps:       c.int,
	format:        Pixel_Format,
}

Texture2D :: struct {
	id:              c.uint,
	width, height:   c.int,
	mipmaps, format: c.int,
}

Render_Texture2D :: struct {
	id:             c.uint,
	texture, depth: Texture2D,
}

Camera2D :: struct {
	offset, target: Vector2,
	rotation, zoom: f32,
}

Glyph_Info :: struct {
	value:              rune,
	offset_x, offset_y: c.int,
	advance_x:          c.int,
	image:              Image,
}

Font :: struct {
	base_size:     c.int,
	glyph_count:   c.int,
	glyph_padding: c.int,
	texture:       Texture2D,
	rectangles:    [^]Rectangle,
	glyphs:        [^]Glyph_Info,
}

Trace_Log_Level :: enum c.int {
	Everything = 0,
	Trace,
	Debug,
	Information,
	Warning,
	Error,
	Fatal,
	Disable,
}

foreign import raylib "../../assets/raylib/libraylib.a"

@(default_calling_convention = "c", require_results)
foreign raylib {
	CheckCollisionPointRec :: proc(point: Vector2, rectangle: Rectangle) -> c.bool ---
	GetScreenToWorld2D :: proc(position: Vector2, camera: Camera2D) -> Vector2 ---

	BeginDrawing :: proc() ---
	BeginMode2D :: proc(camera: Camera2D) ---
	BeginTextureMode :: proc(target: Render_Texture2D) ---
	ClearBackground :: proc(color: Color) ---
	EndDrawing :: proc() ---
	EndMode2D :: proc() ---
	EndTextureMode :: proc() ---

	LoadFontFromMemory :: proc(file_type: cstring, file_data: rawptr, data_size: c.int, font_size: c.int, codepoints: [^]rune, codepoint_count: c.int) -> Font ---
	UnloadFont :: proc(font: Font) ---

	ExportImage :: proc(image: Image, file_name: cstring) -> c.bool ---
	LoadImageFromTexture :: proc(texture: Texture2D) -> Image ---
	LoadRenderTexture :: proc(width, height: c.int) -> Render_Texture2D ---
	LoadTextureFromImage :: proc(image: Image) -> Texture2D ---
	SetTextureFilter :: proc(texture: Texture2D, filter: Texture_Filter) ---
	SetTextureWrap :: proc(texture: Texture2D, wrap: Texture_Wrap) ---
	UnloadImage :: proc(image: Image) ---
	UnloadRenderTexture :: proc(target: Render_Texture2D) ---
	UnloadTexture :: proc(texture: Texture2D) ---

	ImageCrop :: proc(image: ^Image, crop: Rectangle) ---
	ImageDrawLineEx :: proc(dst: ^Image, start_pos, end_pos: Vector2, thickness: c.int, color: Color) ---
	ImageDrawRectangleLinesEx :: proc(dst: ^Image, rectangle: Rectangle, thickness: c.int, color: Color) ---
	ImageDrawRectangleRec :: proc(dst: ^Image, rectangle: Rectangle, color: Color) ---
	ImageDrawTriangle :: proc(dst: ^Image, v1, v2, v3: Vector2, color: Color) ---
	ImageRotateCW :: proc(image: ^Image) ---

	IsKeyDown :: proc(key: Keyboard_Key) -> c.bool ---
	IsKeyPressed :: proc(key: Keyboard_Key) -> c.bool ---
	IsKeyPressedRepeat :: proc(key: Keyboard_Key) -> c.bool ---
	IsKeyReleased :: proc(key: Keyboard_Key) -> c.bool ---

	GetMousePosition :: proc() -> Vector2 ---
	GetMouseWheelMove :: proc() -> f32 ---
	IsMouseButtonDown :: proc(button: Mouse_Button) -> c.bool ---
	IsMouseButtonPressed :: proc(button: Mouse_Button) -> c.bool ---
	IsMouseButtonReleased :: proc(button: Mouse_Button) -> c.bool ---

	DrawCircle :: proc(center_x, center_y: c.int, radius: f32, color: Color) ---
	DrawLineEx :: proc(start_pos, end_pos: Vector2, thickness: f32, color: Color) ---
	DrawRectangle :: proc(pos_x, pos_y, width, height: c.int, color: Color) ---
	DrawRectangleLinesEx :: proc(rectangle: Rectangle, thickness: f32, color: Color) ---
	DrawRectangleRec :: proc(rectangle: Rectangle, color: Color) ---
	DrawTextEx :: proc(font: Font, text: cstring, position: Vector2, font_size, spacing: f32, tint: Color) ---
	DrawTexture :: proc(texture: Texture2D, pos_x, pos_y: c.int, tint: Color) ---
	DrawTexturePro :: proc(texture: Texture2D, source, dest: Rectangle, origin: Vector2, rotation: f32, tint: Color) ---

	CloseWindow :: proc() ---
	GetFrameTime :: proc() -> f32 ---
	GetRenderHeight :: proc() -> c.int ---
	GetRenderWidth :: proc() -> c.int ---
	GetScreenHeight :: proc() -> c.int ---
	GetScreenWidth :: proc() -> c.int ---
	GetWindowScaleDPI :: proc() -> Vector2 ---
	InitWindow :: proc(width, height: c.int, title: cstring) ---
	SetConfigFlags :: proc(flags: Config_Flags) ---
	SetTargetFPS :: proc(fps: c.int) ---
	SetTraceLogLevel :: proc(log_level: Trace_Log_Level) ---
	WindowShouldClose :: proc() -> c.bool ---
}
