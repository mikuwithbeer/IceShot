package error

import "../native"

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
}

message_box :: proc(error: Error) {
	native.unsafe_error_box(to_string(error))
}

@(private)
to_string :: proc(error: Error) -> cstring {
	#partial switch error {
	case .Out_Of_Memory:
		return "Application ran out of memory."
	case .Not_Permitted:
		return "Please enable screen recording permission in System Settings and try again."
	case .Nothing_To_Undo:
		return "There's nothing to undo."
	case .Nothing_To_Redo:
		return "There's nothing to redo."
	case .No_Text_Found:
		return "No text was found."
	case .Failed_To_Open_File:
		return "Could not open the configuration file."
	case .Failed_To_Read_File:
		return "Could not read the configuration file. It may be invalid."
	case .Failed_To_Write_File:
		return "Could not save the configuration file. Check whether the path is valid."
	}

	return "Something went wrong."
}
