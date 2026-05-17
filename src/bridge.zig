const main = @import("main.zig");

pub export fn init() void {
    main.init();
}

pub export fn update(t: f32) void {
    main.update(t);
}

pub export fn get_buffer_ptr() [*]u8 {
    return &main.buffer;
}

pub export fn flip_tile(x: f32, y: f32) void {
    main.flipTileAt(x, y);
}
