const std = @import("std");

const zeika = @import("zeika/zeika.zig");
const math = @import("zeika/math.zig");
const Event = @import("zeika/event.zig").Event;

pub fn main() !void {
    try zeika.init_all("Zig Test", 800, 600, 800, 600);

    while (zeika.is_running()) {
        zeika.update();

        if (zeika.is_key_just_pressed(zeika.InputKey.KeyboardEscape, 0)) {
            break;
        }

        zeika.window_render();
    }

    zeika.shutdown_all();
}
