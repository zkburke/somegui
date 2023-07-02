const std = @import("std");

const CommandBuffer = @This();

const Color = @import("main.zig").Color;

pub const Command = union(enum) {
    filled_rectangle: FilledRectangle,

    pub const FilledRectangle = struct {
        x: u16,
        y: u16,
        width: u16,
        height: u16,
        color: Color,
    };
};

commands: std.ArrayList(Command),

pub fn init(allocator: std.mem.Allocator) CommandBuffer {
    return .{
        .commands = std.ArrayList(Command).init(allocator),
    };
}

pub fn deinit(self: *CommandBuffer) void {
    self.commands.deinit();
    self.* = undefined;
}

pub fn clear(self: *CommandBuffer) void {
    self.commands.clearRetainingCapacity();
}

pub fn addCommand(self: *CommandBuffer, command: Command) void {
    self.commands.append(command) catch unreachable;
}

pub fn drawFilledRectangle(self: *CommandBuffer, rectangle: Command.FilledRectangle) void {
    self.addCommand(.{ .filled_rectangle = rectangle });
}

pub fn iterator(self: *CommandBuffer) Iterator {
    return .{ .command_buffer = self };
}

pub const Iterator = struct {
    command_buffer: *const CommandBuffer,
    index: u32 = 0,

    pub fn next(self: *Iterator) ?Command {
        if (self.index >= self.command_buffer.commands.items.len) {
            return null;
        }

        defer self.index += 1;

        return self.command_buffer.commands.items[self.index];
    }
};
