const std = @import("std");

const Context = @This();
const CommandBuffer = @import("CommandBuffer.zig");

command_buffer: ?*CommandBuffer = null,

pub fn init() Context {
    return .{};
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
