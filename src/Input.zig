const std = @import("std");

const Input = @This();

pub const KeyboardKey = enum {};

pub const MouseButton = enum {
    left,
    right,
    middle,
};

pub const MouseButtonState = enum {
    up,
    down,
    pressed,
    released,
};

mouse_position: @Vector(2, u16),
mouse_buttons: [std.enums.values(MouseButton).len]MouseButtonState = undefined,

pub fn getMouseButton(self: Input, button: MouseButton) MouseButtonState {
    return self.mouse_buttons[@intFromEnum(button)];
}
