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

allocator: std.mem.Allocator,
commands: std.ArrayListUnmanaged(Command),
text_buffer: std.ArrayListUnmanaged(u8),

pub fn init(allocator: std.mem.Allocator) CommandBuffer {
    return .{
        .allocator = allocator,
        .commands = .{},
        .text_buffer = .{},
    };
}

pub fn deinit(self: *CommandBuffer) void {
    self.commands.deinit(self.allocator);
    self.text_buffer.deinit(self.allocator);
    self.* = undefined;
}

pub fn clear(self: *CommandBuffer) void {
    self.commands.clearRetainingCapacity();
    self.text_buffer.clearRetainingCapacity();
}

pub fn addCommand(self: *CommandBuffer, command: Command) void {
    self.commands.append(self.allocator, command) catch unreachable;
}

pub fn drawFilledRectangle(self: *CommandBuffer, rectangle: Command.FilledRectangle) void {
    self.addCommand(.{ .filled_rectangle = rectangle });
}

pub fn drawText(self: *CommandBuffer, text: Command.Text) void {
    self.addCommand(.{ .text = .{
        .x = text.x,
        .y = text.y,
        .string = self.textBuffer(text.string),
        .font_size = text.font_size,
        .font = text.font,
        .color = text.color,
    } });
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

fn textBuffer(self: *CommandBuffer, string: []const u8) []const u8 {
    const start = self.text_buffer.items.len;

    self.text_buffer.appendSlice(self.allocator, string) catch unreachable;

    return self.text_buffer.items[start .. start + string.len];
}
