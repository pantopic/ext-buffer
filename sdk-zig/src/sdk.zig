const abi = @import("abi.zig");

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
        abi.id = self.id;
        abi.set_id = self.set_id;
        abi.__buffer_multi_append(@intFromPtr(b.ptr), @intCast(b.len));
        return abi.err_code == 0;
    }

    pub fn iterator(self: MultiValue) Iterator {
        abi.id = self.id;
        abi.set_id = self.set_id;
        abi.__buffer_multi_load();
        return .{ .buf = abi.buf[0..abi.buf_len] };
    }

    pub fn reset(self: MultiValue) void {
        abi.set_id = self.set_id;
        abi.id = self.id;
        abi.__buffer_multi_reset();
    }
};

pub const Iterator = struct {
    pos: usize = 0,
    buf: []const u8 = undefined,

    pub fn next(self: *Iterator) ?[]const u8 {
        while (self.pos < self.buf.len) {
            var size: u64 = 0;
            var shift: u6 = 0;
            while (self.pos < self.buf.len) {
                const c = self.buf[self.pos];
                self.pos += 1;
                size |= @as(u64, c & 0x7f) << shift;
                if (c < 0x80) break;
                shift += 7;
            }
            if (size == 0) continue;
            const start = self.pos;
            self.pos += @intCast(size);
            return self.buf[start..self.pos];
        }
        return null;
    }
};
