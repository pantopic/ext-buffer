const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("buffer", .{
        .root_source_file = b.path("src/sdk.zig"),
        .target = b.resolveTargetQuery(.{ .cpu_arch = .wasm32, .os_tag = .wasi }),
        .optimize = b.standardOptimizeOption(.{}),
    });
}
