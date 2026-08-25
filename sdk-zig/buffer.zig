const std = @import("std");

var id: u64 = 0;
var size: u64 = 0;
var set_id: u64 = 0;
var err_code: u32 = 0;
var meta: [4]u32 = undefined;

export fn __buffer() u32 {
    meta[0] = @intFromPtr(&id);
    meta[1] = @intFromPtr(&size);
    meta[2] = @intFromPtr(&set_id);
    meta[3] = @intFromPtr(&err_code);
    return @intFromPtr(&meta);
}

extern "pantopic/ext-buffer" fn __buffer_multi_append(ptr: u32, len: u32) void;
extern "pantopic/ext-buffer" fn __buffer_multi_load(ptr: u32, len: u32) u32;
extern "pantopic/ext-buffer" fn __buffer_multi_reset() void;

pub const Options = struct {
    size_limit: u64 = 0,
};

pub const MultiValueSet = struct {
    set_id: u64,
    size: u64 = 0,

    pub fn init(sid: u64, opts: Options) MultiValueSet {
        return .{ .set_id = sid, .size = opts.size_limit };
    }

    pub fn find(self: MultiValueSet, value_id: u64) MultiValue {
        return .{ .id = value_id, .set_id = self.set_id, .size = self.size };
    }
};

pub const MultiValue = struct {
    id: u64,
    set_id: u64,
    size: u64,

    pub fn append(self: MultiValue, b: []const u8) bool {
        if (b.len == 0) {
            return true;
        }
        id = self.id;
        size = self.size;
        set_id = self.set_id;
        __buffer_multi_append(@intFromPtr(b.ptr), @intCast(b.len));
        return err_code == 0;
    }

    pub fn iterator(self: MultiValue, b: []const u8) Iterator {
        id = self.id;
        set_id = self.set_id;
        const read: u32 = __buffer_multi_load(@intFromPtr(b.ptr), @intCast(b.len));
        if (err_code != 0) {
            std.debug.panic("Buffer too small", .{});
        }
        return .{ .buf = b[0..read] };
    }

    pub fn reset(self: MultiValue) void {
        set_id = self.set_id;
        id = self.id;
        __buffer_multi_reset();
    }
};

pub const Iterator = struct {
    pos: usize = 0,
    buf: []const u8 = undefined,

    pub fn next(self: *Iterator) ?[]const u8 {
        while (self.pos < self.buf.len) {
            var s: u64 = 0;
            var shift: u6 = 0;
            while (self.pos < self.buf.len) {
                const c = self.buf[self.pos];
                self.pos += 1;
                s |= @as(u64, c & 0x7f) << shift;
                if (c < 0x80) break;
                shift += 7;
            }
            if (s == 0) continue;
            const start = self.pos;
            self.pos += @intCast(s);
            return self.buf[start..self.pos];
        }
        return null;
    }
};
