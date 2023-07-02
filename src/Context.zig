const std = @import("std");

const Context = @This();
const CommandBuffer = @import("CommandBuffer.zig");
const Input = @import("Input.zig");

allocator: std.mem.Allocator,
command_buffer: ?*CommandBuffer = null,
input: Input = .{},

pub fn init(allocator: std.mem.Allocator) Context {
    return .{
        .allocator = allocator,
    };
}

pub fn deinit(self: *Context) void {
    self.* = undefined;
}

pub fn begin(self: *Context, command_buffer: ?*CommandBuffer) void {
    self.command_buffer = command_buffer;
}

pub fn end(self: *Context) void {
    self.command_buffer = null;
}

pub fn text(self: *Context) void {
    _ = self;
}

fn aabbPointIntersect(position: @Vector(2, u16), size: @Vector(2, u16), point: @Vector(2, u16)) bool {
    return @reduce(.And, point > position) and @reduce(.And, point < position + size);
}

fn aabbAabbIntersect(a_position: @Vector(2, u16), a_size: @Vector(2, u16), b_position: @Vector(2, u16), b_size: @Vector(2, u16)) bool {
    const positions = @Vector(4, u16){ a_position[0], b_position[0], a_position[1], b_position[1] };
    const sizes = @Vector(4, u16){ a_size[0], b_size[0], a_size[1], b_size[1] };

    const cmp_vector = @Vector(4, u16){ b_position[0], a_position[0], b_position[1], a_position[1] };

    return @reduce(.And, positions + sizes > cmp_vector);
}

fn isRegionHovered(self: *Context, position: @Vector(2, u16), size: @Vector(2, u16)) bool {
    return aabbPointIntersect(position, size, self.mouse_position);
}

fn isRegionVisible(self: *Context, position: @Vector(2, u16), size: @Vector(2, u16)) bool {
    return aabbAabbIntersect(.{ self.layout.bounds[0], self.layout.bounds[1] }, .{ self.layout.bounds[2], self.layout.bounds[3] }, position, size);
}
