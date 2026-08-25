const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .wasi,
    });
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSmall });
    const sdk = b.dependency("ext_buffer_sdk", .{});
    const exe = b.addExecutable(.{
        .name = "test-zig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("module.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "buffer", .module = sdk.module("buffer") },
            },
        }),
    });
    exe.rdynamic = true;
    exe.wasi_exec_model = .reactor;
    b.installArtifact(exe);
}
