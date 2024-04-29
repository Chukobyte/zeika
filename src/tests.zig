const std = @import("std");

const math = @import("zeika/math.zig");
const Vec2f = math.Vec2f;

const Event = @import("zeika/event.zig").Event;

// Math Tests
test "math general test" {
    const left_arrow = Vec2f{ .x = 2.0, .y = 5.0 };
    const right_arrow = Vec2f{ .x = 5.0, .y = 7.0 };
    const combined_arrow = Vec2f.Add(&left_arrow, &right_arrow);

    try std.testing.expect(Vec2f.Equals(&combined_arrow, &Vec2f{ .x = 7.0, .y = 12.0 }));
}

// Event Tests
var hasCalledBack = false;

fn testCallbackFunc(message: []const u8) void {
    hasCalledBack = message.ptr == "Hey".ptr;
}

test "event general test" {
    // From main

    // const MessageEventType: type = Event(fn ([]const u8) void);
    // var new_event = MessageEventType.init(std.heap.page_allocator);
    // defer new_event.deinit();
    // _ = new_event.subscribe(struct {
    // pub fn callback (message: []const u8) void {
    //     std.debug.print("Message = {s}\n", .{ message });
    //     }
    // }.callback
    // );
    // new_event.broadcast(.{"Hey"});
    // new_event.clearAndFree();
    // new_event.broadcast(.{"Won't see"});
    //
    // const NumberEventType: type = Event(fn (i32, i32, i32) void);
    // var new_num_event = NumberEventType.init(std.heap.page_allocator);
    // defer new_num_event.deinit();
    // const num_event_handle = new_num_event.subscribe(struct {
    // pub fn callback (value1: i32, value2: i32, value3: i32) void {
    //     std.debug.print("Value = ({d}, {d}, {d})\n", .{ value1, value2, value3 });
    //     }
    // }.callback
    // );
    // new_num_event.broadcast(.{2, 4, 6});
    // new_num_event.unsubscribe(num_event_handle) catch { std.debug.print("Failed to unsub!", .{}); };
    // new_num_event.broadcast(.{88, 3, 9});

    const MessageEventType = Event(fn ([]const u8) void);
    var new_event = MessageEventType.init(std.heap.page_allocator);
    defer new_event.deinit();
    _ = new_event.subscribe(testCallbackFunc);
    new_event.broadcast(.{"Hey"});
    try std.testing.expect(hasCalledBack);
    new_event.clearAndFree();
    new_event.broadcast(.{"Won't see"});
}
