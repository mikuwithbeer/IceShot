package main

import "window"

import "core:fmt"
import "core:mem"

main :: proc() {
	tracking: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking, context.allocator)

	allocator := mem.tracking_allocator(&tracking)
	defer {
		if len(tracking.allocation_map) > 0 {
			fmt.eprintf("--- %v allocations leaked: ---\n", len(tracking.allocation_map))

			for _, entry in tracking.allocation_map {
				fmt.eprintf("* %v bytes : %v\n", entry.size, entry.location)
			}
		} else {
			fmt.println("--- all allocations freed ---")
		}

		mem.tracking_allocator_destroy(&tracking)
	}

	gui, _ := window.init_window(allocator = allocator)
	defer window.free_window(&gui)

	_ = window.load_window(&gui)
}
