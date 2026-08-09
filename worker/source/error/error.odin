package error

import "../native"
import "core:fmt"

Error :: enum {
	None,
	Out_Of_Memory,
	Not_Permitted,
	Nothing_To_Undo,
	Nothing_To_Redo,
	No_Text_Found,
	Failed_To_Open_File,
	Failed_To_Read_File,
	Failed_To_Write_File,
	Invalid_Image_Format,
	Invalid_Theme,
	Failed_To_Upload,
}

message_box :: proc(error: Error) {
	// None is not an error, just return if somehow it gets there.
	if error == .None {
		return
	} else {
		native.unsafe_error_box(to_string(error))
	}
}

@(private)
to_string :: proc(error: Error) -> cstring {
	fmt.println(error)

	#partial switch error {
	case .Out_Of_Memory:
		return "Application ran out of memory."
	case .Not_Permitted:
		return "Please enable screen recording permission in System Settings and try again."
	case .Nothing_To_Undo:
		return "There is nothing to undo." // This message is unreachable
	case .Nothing_To_Redo:
		return "There is nothing to redo." // This message is unreachable
	case .No_Text_Found:
		return "No text was found." // This message is unreachable
	case .Failed_To_Open_File:
		return "Could not open the file."
	case .Failed_To_Read_File:
		return "Could not read the file. It may be invalid."
	case .Failed_To_Write_File:
		return "Could not save the file. Check whether the path is valid."
	case .Invalid_Image_Format:
		return "The configured image format is not supported."
	case .Failed_To_Upload:
		return "Could not upload the image." // This message is unreachable
	case .Invalid_Theme:
		return "The configured theme is not supported."
	}

	return "Something went wrong." // This message is unreachable
}
