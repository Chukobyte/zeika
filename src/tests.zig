const std = @import("std");

const zeika = @import("zeika/zeika.zig");
const math = @import("zeika/math.zig");
const Vec2f = math.Vec2f;
const Rect2 = math.Rect2;

const Event = @import("zeika/event.zig").Event;

// Math Tests
test "math general test" {
    const left_arrow = Vec2f{ .x = 2.0, .y = 5.0 };
    const right_arrow = Vec2f{ .x = 5.0, .y = 7.0 };
    const combined_arrow = Vec2f.Add(&left_arrow, &right_arrow);

    try std.testing.expect(Vec2f.Equals(&combined_arrow, &Vec2f{ .x = 7.0, .y = 12.0 }));

    const rectA = Rect2{ .x = 10.0, .y = 20.0, .w = 64.0, .h = 64.0 };
    const rectB = Rect2{ .x = 5.0, .y = 30.0, .w = 32.0, .h = 32.0 };
    const rectC = Rect2{ .x = 80.0, .y = -30.0, .w = 32.0, .h = 32.0 };
    try std.testing.expect(rectA.doesOverlap(&rectB));
    try std.testing.expect(!rectA.doesOverlap(&rectC));
}

// Event Tests
var hasCalledBack = false;

fn testCallbackFunc(message: []const u8) void {
    hasCalledBack = message.ptr == "Hey".ptr;
}

test "event general test" {
    const MessageEventType = Event(fn ([]const u8) void);
    var new_event = MessageEventType.init(std.heap.page_allocator);
    defer new_event.deinit();
    _ = new_event.subscribe(testCallbackFunc);
    new_event.broadcast(.{"Hey"});
    try std.testing.expect(hasCalledBack);
    new_event.clearAndFree();
    new_event.broadcast(.{"Won't see"});
}

test "get user save path test" {
    const save_path = try zeika.get_user_save_path(.{ .org_name = "chukobyte", .app_name = "test_app", .relative_path = "/save" });
    std.debug.print("save_path = {s}\n", .{ save_path });
}
