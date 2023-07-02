const std = @import("std");
const raylib_build = @import("example/raylib/raylib/src/build.zig");

pub fn build(builder: *std.Build) void {
    const target = builder.standardTargetOptions(.{});
    const optimize = builder.standardOptimizeOption(.{});

    {
        const exe = builder.addExecutable(.{
            .name = "example_raylib",
            .root_source_file = std.build.FileSource.relative("example/raylib/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        builder.installArtifact(exe);

        const raylib = raylib_build.addRaylib(builder, target, optimize, .{});

        exe.linkLibrary(raylib);
        exe.addIncludePath("example/raylib/raylib/src/");
        exe.addAnonymousModule("somegui", .{ .source_file = std.build.FileSource.relative("src/main.zig") });

        const run_cmd = builder.addRunArtifact(exe);

        run_cmd.step.dependOn(builder.getInstallStep());

        const run_step = builder.step("example_raylib", "Run the raylib example");
        run_step.dependOn(&run_cmd.step);
    }

    const main_tests = builder.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_main_tests = builder.addRunArtifact(main_tests);

    const test_step = builder.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}
