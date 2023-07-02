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
