const std = @import("std");

const Font = @This();

glyph_codepoints: []u21,
glyph_rectangles: []const @Vector(4, u16),
glyphs: []const Glyph,
padding_x: u16,
padding_y: u16,
base_size_x: u16,
base_size_y: u16,
///A pointer to client specified data
client_data: ?*anyopaque,

pub fn getGlyphIndex(self: Font, codepoint: u21) ?usize {
    for (self.glyph_codepoints, 0..) |glyph_codepoint, i| {
        if (glyph_codepoint == codepoint) {
            return i;
        }
    }

    return null;
}

pub fn getGlyph(self: Font, codepoint: u21) ?Glyph {
    return self.glyphs[self.getGlyphIndex(codepoint) orelse return null];
}

///Returns the size that text drawn with this font will occupy in the display space
pub fn measureText(self: Font, string: []const u8, font_size: u16) @Vector(2, u16) {
    const spacing = @max(10, font_size);

    var temp_byte_counter: usize = 0;
    var byte_counter: usize = 0;

    var text_width: u16 = 0;
    var text_height = self.base_size_x;
    var temp_text_width: u16 = 0;

    const scale_factor = font_size / self.base_size_x;

    var iterator = std.unicode.Utf8Iterator{ .bytes = string, .i = 0 };

    while (iterator.nextCodepoint()) |codepoint| {
        const glyph_index = self.getGlyphIndex(codepoint);

        byte_counter += 1;

        if (codepoint != '\n') {
            if (glyph_index != null) {
                const glyph = self.glyphs[glyph_index.?];

                if (glyph.size_x != 0) {
                    text_width += glyph.size_x;
                } else {
                    const rectangle = self.glyph_rectangles[glyph_index.?];

                    text_width += rectangle[2] + glyph.offset_x;
                }
            }
        } else {
            if (temp_text_width < text_width) temp_text_width = text_width;

            byte_counter = 0;
            text_width = 0;
            text_height += self.base_size_x + self.base_size_x / 2;
        }

        if (temp_byte_counter < byte_counter) temp_byte_counter = byte_counter;
    }

    if (temp_text_width < text_width) temp_text_width = text_width;

    return .{
        temp_text_width * scale_factor + @as(u16, @intCast(temp_byte_counter - 1)) * spacing,
        text_height * scale_factor,
    };
}

pub const Glyph = struct {
    offset_x: u16,
    offset_y: u16,
    size_x: u16,
    size_y: u16,
};
