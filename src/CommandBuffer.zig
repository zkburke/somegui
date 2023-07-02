const std = @import("std");

const CommandBuffer = @This();

const Color = @import("main.zig").Color;
const Font = @import("main.zig").Font;

pub const Command = union(enum) {
    filled_rectangle: FilledRectangle,
    text: Text,

    pub const FilledRectangle = struct {
        x: u16,
        y: u16,
        width: u16,
        height: u16,
        color: Color,
    };

    pub const Text = struct {
        string: []const u8,
        x: u16,
        y: u16,
        font_size: u16,
        font: *const Font,
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

pub fn drawText(self: *CommandBuffer, text: Command.Text) void {
    self.addCommand(.{ .text = text });
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
