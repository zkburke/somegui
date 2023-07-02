const std = @import("std");
const testing = std.testing;

pub const Context = @import("Context.zig");
pub const CommandBuffer = @import("CommandBuffer.zig");

pub const Color = packed struct(u32) {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub const black: Color = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
    pub const white: Color = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
    pub const red: Color = .{ .r = 255, .g = 0, .b = 0, .a = 255 };
    pub const green: Color = .{ .r = 0, .g = 255, .b = 0, .a = 255 };
    pub const blue: Color = .{ .r = 0, .g = 0, .b = 255, .a = 255 };
};

test {
    _ = Context;
    _ = CommandBuffer;
}
