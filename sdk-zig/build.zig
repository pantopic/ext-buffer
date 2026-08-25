const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("buffer", .{
        .root_source_file = b.path("buffer.zig"),
    });
}
