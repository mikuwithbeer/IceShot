package action

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"

import "vendor:raylib"

Save_Action :: struct {
	date: time.Time,
	path: string,
}

save_action :: proc(
	texture: raylib.Texture2D,
	allocator := context.allocator,
) -> (
	Save_Action,
	Action_Error,
) {
	image := raylib.LoadImageFromTexture(texture)

	home := os.get_env_alloc("HOME", allocator = allocator)
	defer delete(home, allocator = allocator)

	date := time.now()
	year, month, day := time.year(date), time.month(date), time.day(date)
	hour, minute, second := time.clock_from_time(date)

	path := fmt.aprintf(
		"%s/Documents/Screenshots/SCR-%04d%02d%02d-%02d%02d%02d.png",
		home,
		year,
		month,
		day,
		hour,
		minute,
		second,
		allocator = allocator,
	)

	null_path := strings.clone_to_cstring(path, allocator = allocator)

	defer delete(null_path, allocator = allocator)

	ok := raylib.ExportImage(image, null_path)
	if !ok {
		return {}, .Write_Error
	}

	return {date = date, path = path}, .None
}
