package manage

Manage :: struct {
	crop:    Manage_Crop,
	frame:   Manage_Frame,
	history: Manage_History,
}

@(require_results)
init_manage :: proc(allocator := context.allocator) -> (manager: Manage, ok: bool) {
	manager.history = init_history(allocator = allocator) or_return

	ok = true
	return
}

free_manage :: proc(manager: ^Manage) {
	free_history(&manager.history)
}
