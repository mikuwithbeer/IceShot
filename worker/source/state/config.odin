package state

import "../error"
import "../native"

import "base:runtime"

import "core:encoding/json"
import "core:fmt"
import "core:os"

@(private = "file")
CONFIG_DIRECTORY :: ".iceshot"

@(private = "file")
CONFIG_FILE :: "worker.json"

@(private = "file")
CONFIG_DEFAULT :: `{
  "save": {
    "path": "Documents/Screenshots",
    "format": "PNG",
    "reveal": true
  },
  "upload": {
    "imgbb": null
  },
  "appearance": {
    "theme": "system"
  }
}
`

@(private)
Save :: struct {
	path:   string,
	format: string,
	reveal: bool,
}

@(private)
Upload :: struct {
	imgbb: Maybe(string),
}

@(private)
Appearance :: struct {
	theme: string,
}

Config :: struct {
	save:       Save,
	upload:     Upload,
	appearance: Appearance,
	_home:      string `json:"-"`,
	_allocator: runtime.Allocator `json:"-"`,
}

@(private, require_results)
init_config :: proc(allocator := context.allocator) -> (config: Config, err: error.Error) {
	home_directory, os_err := os.user_home_dir(allocator = allocator)
	if os_err != os.ERROR_NONE {
		err = .Out_Of_Memory // It might not be an allocation issue?
		return
	}

	defer if err != .None do delete(home_directory, allocator = allocator)

	config_directory := fmt.aprintf(
		"%s/%s",
		home_directory,
		CONFIG_DIRECTORY,
		allocator = allocator,
	)

	defer delete(config_directory, allocator = allocator)

	os.make_directory(config_directory) // This needs a better error handling

	config_file := fmt.aprintf("%s/%s", config_directory, CONFIG_FILE, allocator = allocator)

	defer delete(config_file, allocator = allocator)

	file: ^os.File
	file, os_err = os.open(
		config_file,
		{.Create, .Read, .Write},
		perm = {.Read_User, .Read_Other, .Read_Group, .Write_User},
	)

	if os_err != os.ERROR_NONE {
		err = .Failed_To_Open_File
		return
	}

	defer os.close(file)

	file_size: i64
	file_size, os_err = os.file_size(file)
	if os_err != os.ERROR_NONE {
		err = .Failed_To_Open_File
		return
	}

	if file_size == 0 {
		_, os_err = os.write_string(file, CONFIG_DEFAULT)
		if os_err != os.ERROR_NONE {
			err = .Failed_To_Write_File
			return
		}

		os_err = os.sync(file)
		if os_err != os.ERROR_NONE {
			err = .Failed_To_Write_File
			return
		}
	}

	_, os_err = os.seek(file, 0, .Start) // Move to beginning in case of write
	if os_err != os.ERROR_NONE {
		err = .Failed_To_Read_File
		return
	}

	raw_config: []byte
	raw_config, os_err = os.read_entire_file_from_file(file, allocator = allocator)
	if os_err != os.ERROR_NONE {
		err = .Failed_To_Read_File
		return
	}

	defer delete(raw_config, allocator = allocator)

	json_err := json.unmarshal(raw_config, &config, allocator = allocator) // Might change specification in the future
	if json_err != nil {
		err = .Failed_To_Read_File
		return
	}

	switch config.save.format {
	case "png", "PNG", "jpg", "JPG", "jpeg", "JPEG", "bmp", "BMP":
		break
	case:
		err = .Invalid_Image_Format
		return
	}

	fmt.println(config)
	switch config.appearance.theme {
	case "dark", "light", "system":
		break
	case:
		err = .Invalid_Theme
		return
	}

	config._home = home_directory
	config._allocator = allocator

	return
}

@(require_results)
get_home_path :: proc(config: ^Config) -> string {
	return config._home
}

@(require_results)
is_dark_mode :: proc(config: ^Config) -> bool {
	switch config.appearance.theme {
	case "dark":
		return true
	case "light":
		return false
	case:
		return native.unsafe_dark_mode()
	}
}

@(private)
free_config :: proc(config: ^Config) {
	delete(config.save.path, allocator = config._allocator)
	delete(config.save.format, allocator = config._allocator)

	if imgbb, ok := config.upload.imgbb.?; ok {
		delete(imgbb, allocator = config._allocator)
	}

	delete(config.appearance.theme, allocator = config._allocator)

	delete(config._home, allocator = config._allocator)
}
