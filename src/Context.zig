const std = @import("std");

const Context = @This();
const CommandBuffer = @import("CommandBuffer.zig");
const Input = @import("Input.zig");
const Font = @import("Font.zig");
const Color = @import("main.zig").Color;

allocator: std.mem.Allocator,
command_buffer: ?*CommandBuffer = null,
input: Input = .{},
font: *const Font = undefined,
layout: Layout = .{
    .bounds = @Vector(4, u16){ 0, 0, 0, 0 },
    .item_padding = @Vector(2, u16){ 10, 10 },
    .item_offset = @Vector(2, u16){ 0, 0 },
    .item_size = @Vector(2, u16){ 0, 0 },
},
largest_button_size: @Vector(2, u16) = @Vector(2, u16){ 0, 0 },

pub const Layout = struct {
    bounds: @Vector(4, u16),
    item_padding: @Vector(2, u16),
    item_offset: @Vector(2, u16),
    item_size: @Vector(2, u16),
};

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

    self.layout.item_offset = .{ 0, 0 };
    self.largest_button_size = .{ 0, 0 };
}

pub fn end(self: *Context) void {
    self.command_buffer = null;
}

///Specifies a new line for layout elements
pub fn beginRow(self: *Context) void {
    self.layout.item_offset[0] = 0;
    self.layout.item_offset[1] += self.largest_button_size[1] + self.layout.item_padding[1];
    self.largest_button_size = .{ 0, 0 };
}

pub fn drawText(self: *Context, x: u16, y: u16, font_size: u16, string: []const u8, color: Color, font: *const Font) void {
    (self.command_buffer orelse unreachable).drawText(.{
        .x = x,
        .y = y,
        .font_size = font_size,
        .string = string,
        .color = color,
        .font = font,
    });
}

///Specifies a unicode encoded text box
pub fn text(self: *Context, string: []const u8) void {
    // const font = self.getFont().?;
    const font = self.font;
    // const font_size = self.font_size;
    const font_size = 20;

    const position = self.layout.item_offset;
    const text_size = font.measureText(string, font_size);

    self.largest_button_size = @max(self.largest_button_size, text_size);
    self.layout.item_offset[0] += position[0] + text_size[0] + self.layout.item_padding[0];

    if (!self.isRegionVisible(position, text_size)) {
        return;
    }

    self.command_buffer.?.drawFilledRectangle(.{
        .x = position[0],
        .y = position[1],
        .width = text_size[0],
        .height = text_size[1],
        .color = Color.red,
    });
    self.drawText(position[0], position[1], font_size, string, Color.black, font);
}

///Specifies a unicode encoded text box formatted with std.fmt
pub fn textFormat(self: *Context, comptime format: []const u8, args: anytype) void {
    if (args.len == 0) {
        return self.text(format);
    }

    //TODO error handling is unsafe
    //TODO determine upper bound using parsing
    const format_buffer_length = 1024;
    const character_count = std.fmt.count(format, args);

    if (character_count <= format_buffer_length) {
        var format_buffer: [format_buffer_length]u8 = undefined;

        self.text(std.fmt.bufPrint(&format_buffer, format, args) catch unreachable);
    } else {
        const format_buffer = self.allocator.alloc(u8, character_count) catch unreachable;
        defer self.allocator.free(format_buffer);

        self.text(std.fmt.bufPrint(format_buffer, format, args) catch unreachable);
    }
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
