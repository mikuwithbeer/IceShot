package state

Crop :: struct {
	running:  bool,
	dragging: bool,
	start:    [2]f32,
	end:      [2]f32,
}
