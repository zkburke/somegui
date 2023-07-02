const std = @import("std");
const c = @cImport(@cInclude("raylib.h"));

pub fn main() !void {
    std.log.info("hello, world!", .{});

    c.InitWindow(640, 480, "raylib example");
    defer c.CloseWindow();

    c.SetWindowState(c.FLAG_WINDOW_RESIZABLE);
    c.SetTargetFPS(60);

    while (!c.WindowShouldClose()) {
        c.BeginDrawing();
        defer c.EndDrawing();

        c.ClearBackground(c.RAYWHITE);
    }
}
