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

    var gui_context = somegui.Context.init(allocator);
    defer gui_context.deinit();

    var gui_commands = somegui.CommandBuffer.init(allocator);
    defer gui_commands.deinit();

    while (!c.WindowShouldClose()) {
        c.BeginDrawing();
        defer c.EndDrawing();

        c.ClearBackground(c.RAYWHITE);

        {
            gui_context.begin(&gui_commands);
            defer gui_context.deinit();

            gui_commands.drawFilledRectangle(.{
                .x = 0,
                .y = 0,
                .width = 100,
                .height = 100,
                .color = somegui.Color.red,
            });
        }

        var command_iterator = gui_commands.iterator();

        while (command_iterator.next()) |command| {
            switch (command) {
                .filled_rectangle => |filled_rectangle| {
                    c.DrawRectangle(@intCast(filled_rectangle.x), @intCast(filled_rectangle.y), @intCast(filled_rectangle.width), @intCast(filled_rectangle.height), .{
                        .r = filled_rectangle.color.r,
                        .g = filled_rectangle.color.g,
                        .b = filled_rectangle.color.b,
                        .a = filled_rectangle.color.a,
                    });
                },
            }
        }

        gui_commands.clear();
    }
}
