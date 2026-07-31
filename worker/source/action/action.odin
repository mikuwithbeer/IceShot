package action

Action_Error :: enum {
	None,
	Out_Of_Memory,
	Accessibility_Error,
	Write_Error,
}

Action :: union {
	Capture_Action,
	Crop_Action,
	Save_Action,
}

free_action :: proc(action: Action, allocator := context.allocator) {
	#partial switch act in action {
	case Save_Action:
		delete(act.path, allocator = allocator)
	}
}
