const std = @import("std");

const CommandBuffer = @This();

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub const black: Color = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
    pub const white: Color = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
};

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

commands: std.ArrayList(Command) = .{},

pub fn init() CommandBuffer {
    return .{};
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

        return self.command_buffer.commands.items[self.index];
    }
};
