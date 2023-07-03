const std = @import("std");
const c = @cImport(@cInclude("raylib.h"));
const somegui = @import("somegui");

pub fn main() !void {
    std.log.info("hello, world!", .{});

    c.InitWindow(640, 480, "raylib example");
    defer c.CloseWindow();

    c.SetWindowState(c.FLAG_WINDOW_RESIZABLE);
    c.SetTargetFPS(60);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() != .leak);

    const allocator = gpa.allocator();

    var gui = somegui.Context.init(allocator);
    defer gui.deinit();

    var gui_commands = somegui.CommandBuffer.init(allocator);
    defer gui_commands.deinit();

    var raylib_font = c.GetFontDefault();

    var font = try raylibFontToGuiFont(allocator, &raylib_font);
    defer raylibFontToGuiFontFree(allocator, font);

    while (!c.WindowShouldClose()) {
        c.BeginDrawing();
        defer c.EndDrawing();

        c.ClearBackground(c.RAYWHITE);

        {
            gui.input.mouse_position = .{ @as(u16, @intFromFloat(std.math.fabs(c.GetMousePosition().x))), @as(u16, @intFromFloat(std.math.fabs(c.GetMousePosition().y))) };

            gui.input.mouse_buttons[@intFromEnum(somegui.Input.MouseButton.left)] =
                if (c.IsMouseButtonPressed(c.MOUSE_BUTTON_LEFT))
                somegui.Input.MouseButtonState.pressed
            else if (c.IsMouseButtonReleased(c.MOUSE_BUTTON_LEFT))
                somegui.Input.MouseButtonState.released
            else if (c.IsMouseButtonUp(c.MOUSE_BUTTON_LEFT))
                somegui.Input.MouseButtonState.up
            else if (c.IsMouseButtonDown(c.MOUSE_BUTTON_LEFT))
                somegui.Input.MouseButtonState.down
            else
                unreachable;

            gui.begin(&gui_commands);
            defer gui.end();

            gui.font = &font;
            gui.layout.bounds = .{ 0, 0, @as(u16, @intCast(c.GetScreenWidth())), @as(u16, @intCast(c.GetScreenHeight())) };

            gui.newRow();

            // gui_context.textFormat("hello, {s}", .{"world"});
            gui.text("hello, world");
            gui.text("what a lovely world");

            gui.newRow();

            gui.text("what a lovely world");
            gui.text("what a lovely world");

            gui.newRow();

            switch (gui.button("BUTTON", .{ 100, 40 })) {
                .pressed => {
                    std.log.info("PRESSED BUTTON", .{});
                },
                else => {},
            }
        }

        var command_iterator = gui_commands.iterator();

        while (command_iterator.next()) |command| {
            switch (command) {
                .filled_rectangle => |filled_rectangle| {
                    c.DrawRectangle(
                        @intCast(filled_rectangle.x),
                        @intCast(filled_rectangle.y),
                        @intCast(filled_rectangle.width),
                        @intCast(filled_rectangle.height),
                        .{
                            .r = filled_rectangle.color.r,
                            .g = filled_rectangle.color.g,
                            .b = filled_rectangle.color.b,
                            .a = filled_rectangle.color.a,
                        },
                    );
                },
                .text => |text| {
                    drawTextLenFont(
                        @as(?*const c.Font, @ptrCast(@alignCast(text.font.client_data))).?.*,
                        text.string,
                        @as(c_int, @intCast(text.x)),
                        @as(c_int, @intCast(text.y)),
                        @as(c_int, @intCast(text.font_size)),
                        .{
                            .r = text.color.r,
                            .g = text.color.g,
                            .b = text.color.b,
                            .a = text.color.a,
                        },
                    );
                },
            }
        }

        gui_commands.clear();
    }
}

pub fn raylibFontToGuiFont(allocator: std.mem.Allocator, font: *c.Font) !somegui.Font {
    const glyphs = try allocator.alloc(somegui.Font.Glyph, @as(usize, @intCast(font.glyphCount)));
    const glyph_codepoints = try allocator.alloc(u21, glyphs.len);
    const glyph_rectangles = try allocator.alloc(@Vector(4, u16), @as(usize, @intCast(font.glyphCount)));

    for (glyphs, 0..) |*glyph, i| {
        const raylib_glyph = font.glyphs[i];
        const raylib_rectangle = font.recs[i];

        glyph_codepoints[i] = @as(u21, @intCast(raylib_glyph.value));

        glyph.size_x = @as(u16, @intCast(raylib_glyph.advanceX));
        glyph.size_y = @as(u16, @intCast(font.baseSize));
        glyph.offset_x = @as(u16, @intCast(raylib_glyph.offsetX));
        glyph.offset_y = @as(u16, @intCast(raylib_glyph.offsetY));

        glyph_rectangles[i] = .{
            @as(u16, @intFromFloat(raylib_rectangle.x)),
            @as(u16, @intFromFloat(raylib_rectangle.y)),
            @as(u16, @intFromFloat(raylib_rectangle.width)),
            @as(u16, @intFromFloat(raylib_rectangle.height)),
        };
    }

    return somegui.Font{
        .glyphs = glyphs,
        .glyph_codepoints = glyph_codepoints,
        .glyph_rectangles = glyph_rectangles,
        .padding_x = @as(u16, @intCast(font.glyphPadding)),
        .padding_y = @as(u16, @intCast(font.glyphPadding)),
        .base_size_x = @as(u16, @intCast(font.baseSize)),
        .base_size_y = @as(u16, @intCast(font.baseSize)),
        .client_data = font,
    };
}

pub fn raylibFontToGuiFontFree(allocator: std.mem.Allocator, font: somegui.Font) void {
    allocator.free(font.glyph_codepoints);
    allocator.free(font.glyphs);
    allocator.free(font.glyph_rectangles);
}

pub fn measureTextExLen(font: c.Font, text: []const u8, font_size: f32, spacing: f32) c.Vector2 {
    var tempByteCounter: usize = 0;
    var byteCounter: usize = 0;

    var textWidth: f32 = 0;
    var textHeight = @as(f32, @floatFromInt(font.baseSize));
    var tempTextWidth: f32 = 0;

    const scale_factor = font_size / @as(f32, @floatFromInt(font.baseSize));

    var iterator = std.unicode.Utf8Iterator{ .bytes = text, .i = 0 };

    while (iterator.nextCodepoint()) |codepoint| {
        byteCounter += 1;

        const index = @as(usize, @intCast(c.GetGlyphIndex(font, @as(c_int, @intCast(codepoint)))));

        if (codepoint != '\n') {
            if (font.glyphs[index].advanceX != 0) {
                textWidth += @as(f32, @floatFromInt(font.glyphs[index].advanceX));
            } else {
                textWidth += (font.recs[index].width + @as(f32, @floatFromInt(font.glyphs[index].offsetX)));
            }
        } else {
            if (tempTextWidth < textWidth) tempTextWidth = textWidth;

            byteCounter = 0;
            textWidth = 0;
            textHeight += @as(f32, @floatFromInt(font.baseSize)) * 1.5;
        }

        if (tempByteCounter < byteCounter) tempByteCounter = byteCounter;
    }

    if (tempTextWidth < textWidth) tempTextWidth = textWidth;

    return .{ .x = tempTextWidth * scale_factor + @as(f32, @floatFromInt(tempByteCounter - 1)) * spacing, .y = textHeight * scale_factor };
}

pub fn measureTextLen(font: c.Font, text: []const u8, font_size: f32) c.Vector2 {
    const default_font_size: c_int = 10; // Default Font chars height in pixel

    var _font_size = if (@as(c_int, @intFromFloat(font_size)) < default_font_size) default_font_size else @as(c_int, @intFromFloat(font_size));

    const spacing = @divFloor(_font_size, default_font_size);

    return measureTextExLen(font, text, @as(f32, @floatFromInt(_font_size)), @as(f32, @floatFromInt(spacing)));
}

pub fn drawTextExLen(font: c.Font, text: []const u8, position: c.Vector2, font_size: f32, spacing: f32, tint: c.Color) void {
    var text_offset_y: c_int = 0;
    var text_offset_x: f32 = 0;

    var scale_factor: f32 = font_size / @as(f32, @floatFromInt(font.baseSize)); // Character quad scaling factor

    var interator = std.unicode.Utf8Iterator{ .bytes = text, .i = 0 };

    while (interator.nextCodepoint()) |codepoint| {
        const glyph_index = @as(usize, @intCast(c.GetGlyphIndex(font, @as(c_int, @intCast(codepoint)))));

        if (codepoint == '\n') {
            text_offset_y += @as(c_int, @intFromFloat((@as(f32, @floatFromInt(font.baseSize)) + @as(f32, @floatFromInt(font.baseSize)) / 2) * scale_factor));
            text_offset_x = 0;
        } else {
            if (codepoint != ' ' and codepoint != '\t') {
                c.DrawTextCodepoint(font, @as(c_int, @intCast(codepoint)), .{ .x = position.x + text_offset_x, .y = position.y + @as(f32, @floatFromInt(text_offset_y)) }, font_size, tint);
            }

            if (font.glyphs[glyph_index].advanceX == 0) {
                text_offset_x += font.recs[glyph_index].width * scale_factor + spacing;
            } else {
                text_offset_x += @as(f32, @floatFromInt(font.glyphs[glyph_index].advanceX)) * scale_factor + spacing;
            }
        }
    }
}

pub fn drawTextLen(text: []const u8, posX: c_int, posY: c_int, font_size: c_int, color: c.Color) void {
    const font = c.GetFontDefault();

    // Check if default font has been loaded
    if (font.texture.id == 0) return;

    var position = c.Vector2{ .x = @as(f32, @floatFromInt(posX)), .y = @as(f32, @floatFromInt(posY)) };

    const default_font_size: c_int = 10; // Default Font chars height in pixel

    var _font_size = if (font_size < default_font_size) default_font_size else font_size;

    const spacing = @divFloor(_font_size, default_font_size);

    drawTextExLen(font, text, position, @as(f32, @floatFromInt(_font_size)), @as(f32, @floatFromInt(spacing)), color);
}

pub fn drawTextLenFont(font: c.Font, text: []const u8, posX: c_int, posY: c_int, font_size: c_int, color: c.Color) void {
    var position = c.Vector2{ .x = @as(f32, @floatFromInt(posX)), .y = @as(f32, @floatFromInt(posY)) };

    const default_font_size: c_int = 10; // Default Font chars height in pixel

    var _font_size = if (font_size < default_font_size) default_font_size else font_size;

    const spacing = @divFloor(_font_size, default_font_size);

    drawTextExLen(font, text, position, @as(f32, @floatFromInt(_font_size)), @as(f32, @floatFromInt(spacing)), color);
}
