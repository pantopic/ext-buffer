const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("buffer_pool", .{
        .root_source_file = b.path("buffer_pool.zig"),
    });
}
