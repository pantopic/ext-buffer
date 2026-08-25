const std = @import("std");
const buffer = @import("buffer");

var buf: [1 << 10]u8 = undefined;

const BUFFER_POOL_MULTI_SET_1 = 0;

const test_multi = buffer.MultiValueSet.init(BUFFER_POOL_MULTI_SET_1, .{ .size_limit = buf.len });

export fn _initialize() void {}

export fn testMultiSetAppend(id: u64, v: u64) void {
    var b: [8]u8 = undefined;
    std.mem.writeInt(u64, &b, v, .little);
    _ = test_multi.find(id).append(&b);
}

export fn testMultiSetIter(id: u64) u64 {
    var total: u64 = 0;
    var it = test_multi.find(id).iterator(&buf);
    while (it.next()) |item| {
        total += std.mem.readInt(u64, item[0..8], .little);
    }
    return total;
}

export fn testMultiSetReset(id: u64) void {
    test_multi.find(id).reset();
}
