package state

import "../error"

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
  "save_path": "Documents/Screenshots",
  "dark_mode": true
}
`

Config :: struct {
	save_path:  string,
	dark_mode:  bool,
	_home_path: string `json:"-"`,
	_allocator: runtime.Allocator `json:"-"`,
}

@(private, require_results)
init_config :: proc(allocator := context.allocator) -> (config: Config, err: error.Error) {
	home_directory, os_err := os.user_home_dir(allocator = allocator)
	if os_err != os.ERROR_NONE {
		err = .Out_Of_Memory
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

	os.make_directory(config_directory) // TODO: proper error handling

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

	_, os_err = os.seek(file, 0, .Start)
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

	json_err := json.unmarshal(raw_config, &config, .JSON5, allocator = allocator)
	if json_err != nil {
		err = .Failed_To_Read_File
		return
	}

	config._home_path = home_directory
	config._allocator = allocator

	return
}

@(require_results)
home_config :: proc(config: ^Config) -> string {
	return config._home_path
}

@(private)
free_config :: proc(config: ^Config) {
	delete(config.save_path, allocator = config._allocator)
	delete(config._home_path, allocator = config._allocator)
}
