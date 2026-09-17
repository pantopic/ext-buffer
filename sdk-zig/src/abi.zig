pub const buf_cap_bytes: u32 = 1536 * 1024;

pub var meta: [6]u32 = undefined;

pub var id: u64 = 0;
pub var set_id: u64 = 0;
pub var buf_cap: u32 = buf_cap_bytes;
pub var buf_len: u32 = 0;
pub var buf: [buf_cap_bytes]u8 = undefined;
pub var err_code: u32 = 0;

export fn __buffer() u32 {
    meta[0] = @intFromPtr(&id);
    meta[1] = @intFromPtr(&set_id);
    meta[2] = @intCast(@intFromPtr(&buf_cap));
    meta[3] = @intCast(@intFromPtr(&buf_len));
    meta[4] = @intCast(@intFromPtr(&buf[0]));
    meta[5] = @intFromPtr(&err_code);
    return @intCast(@intFromPtr(&meta));
}

pub extern "pantopic/ext-buffer" fn __buffer_multi_append(ptr: u32, len: u32) void;
pub extern "pantopic/ext-buffer" fn __buffer_multi_load() void;
pub extern "pantopic/ext-buffer" fn __buffer_multi_reset() void;
