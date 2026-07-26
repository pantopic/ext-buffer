const buf_cap: u32 = 1536 << 10; // 1.5 MiB

var id: u64 = 0;
var set_id: u64 = 0;
var buf_cap_var: u32 = buf_cap;
var buf_len: u32 = 0;
var buf: [buf_cap]u8 = undefined;
var err_code: u32 = 0;
var meta: [6]u32 = undefined;

export fn __buffer_pool() u32 {
    meta[0] = @intFromPtr(&id);
    meta[1] = @intFromPtr(&set_id);
    meta[2] = @intFromPtr(&buf_cap_var);
    meta[3] = @intFromPtr(&buf_len);
    meta[4] = @intFromPtr(&buf);
    meta[5] = @intFromPtr(&err_code);
    return @intFromPtr(&meta);
}

extern "pantopic/wazero-buffer-pool" fn __buffer_pool_multi_append(ptr: u32, len: u32) void;
extern "pantopic/wazero-buffer-pool" fn __buffer_pool_multi_load() void;
extern "pantopic/wazero-buffer-pool" fn __buffer_pool_multi_reset() void;

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
        set_id = self.set_id;
        __buffer_pool_multi_append(@intFromPtr(b.ptr), @intCast(b.len));
        return err_code == 0;
    }

    pub fn iterator(self: MultiValue) Iterator {
        id = self.id;
        set_id = self.set_id;
        __buffer_pool_multi_load();
        return .{};
    }

    pub fn reset(self: MultiValue) void {
        set_id = self.set_id;
        id = self.id;
        __buffer_pool_multi_reset();
    }
};

pub const Iterator = struct {
    pos: usize = 0,

    pub fn next(self: *Iterator) ?[]const u8 {
        while (self.pos < buf_len) {
            var size: u64 = 0;
            var shift: u6 = 0;
            while (self.pos < buf_len) {
                const c = buf[self.pos];
                self.pos += 1;
                size |= @as(u64, c & 0x7f) << shift;
                if (c < 0x80) break;
                shift += 7;
            }
            if (size == 0) continue;
            const start = self.pos;
            self.pos += @intCast(size);
            return buf[start..self.pos];
        }
        return null;
    }
};
