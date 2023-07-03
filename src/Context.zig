const std = @import("std");

const Context = @This();
const CommandBuffer = @import("CommandBuffer.zig");
const Input = @import("Input.zig");
const Font = @import("Font.zig");
const Color = @import("main.zig").Color;
const Style = @import("Style.zig");

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
largest_element_size: @Vector(2, u16) = @Vector(2, u16){ 0, 0 },
style: Style = .{
    .primary_color = .{
        .r = 50,
        .g = 50,
        .b = 50,
        .a = 255,
    },
    .secondary_color = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
},

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
    self.largest_element_size = .{ 0, 0 };
}

pub fn end(self: *Context) void {
    self.command_buffer = null;
}

///Specifies a new line for layout elements
pub fn newRow(self: *Context) void {
    self.layout.item_offset[0] = 0;
    self.layout.item_offset[1] += self.largest_element_size[1] + self.layout.item_padding[1];
    self.largest_element_size = .{ 0, 0 };
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

    self.largest_element_size = @max(self.largest_element_size, text_size);
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

pub const ButtonState = enum {
    idle,
    hovered,
    pressed,
    down,
};

///Specifies a button with a unicode encoded name, and returns true if the button is pressed, otherwise false.
pub fn button(self: *Context, name: []const u8, size: @Vector(2, u16)) ButtonState {
    const idle_color = self.style.primary_color;
    const hovered_color = Color{ .r = 130, .g = 130, .b = 130, .a = 255 };
    const down_color = Color{ .r = 80, .g = 80, .b = 80, .a = 255 };
    const font_size = 10;

    //TODO raylib dependency
    const text_size = self.font.measureText(name, font_size);

    const position = self.layout.item_offset;
    const real_size = @max(text_size * @splat(2, @as(u16, 2)), size);

    if (!self.isRegionVisible(position, real_size)) {
        return .idle;
    }

    const text_position = position + text_size / @splat(2, @as(u16, 2));

    self.largest_element_size = @max(self.largest_element_size, real_size);
    self.layout.item_offset[0] += position[0] + real_size[0] + self.layout.item_padding[0];

    const is_hovered = self.isRegionHovered(position, real_size);
    const is_pressed = is_hovered and self.input.getMouseButton(.left) == .pressed;
    const is_down = is_hovered and self.input.getMouseButton(.left) == .down;

    var state: ButtonState = .idle;

    if (is_hovered) {
        state = .hovered;
    }

    if (is_pressed) {
        state = .pressed;
    }

    if (is_down) {
        state = .down;
    }

    const color = if (is_down) down_color else if (is_hovered) hovered_color else idle_color;

    self.command_buffer.?.drawFilledRectangle(.{
        .x = position[0],
        .y = position[1],
        .width = real_size[0],
        .height = real_size[1],
        .color = color,
    });

    if (!self.isRegionVisible(text_position, text_size)) {
        return state;
    }

    const font = self.font;

    self.drawText(text_position[0], text_position[1], font_size, name, Color.white, font);

    return state;
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
    return aabbPointIntersect(position, size, self.input.mouse_position);
}

fn isRegionVisible(self: *Context, position: @Vector(2, u16), size: @Vector(2, u16)) bool {
    return aabbAabbIntersect(.{ self.layout.bounds[0], self.layout.bounds[1] }, .{ self.layout.bounds[2], self.layout.bounds[3] }, position, size);
}
