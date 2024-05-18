const std = @import("std");

pub fn Event(comptime T: type) type {
    return struct {
        const SubscriberHandle = u32;

        const Subscriber = struct {
            callback: *const T,
            handle: SubscriberHandle = 0,
        };

        subscribers: std.ArrayList(Subscriber),
        handle_index: SubscriberHandle = 1,

        /// Initializes event, call 'deinit' once completely finished with the event.
        pub fn init(allocator: std.mem.Allocator) @This() {
            return @This(){
                .subscribers = std.ArrayList(Subscriber).init(allocator),
            };
        }

        /// Deinitializes the event.
        pub fn deinit(self: *@This()) void {
            self.subscribers.deinit();
        }

        /// Broadcasts the event to all subscribers.  Args passed in much match callback function's params.
        pub fn broadcast(self: *@This(), args: anytype) void {
            for (self.subscribers.items) |subscriber| {
                @call(.auto, subscriber.callback, args);
            }
        }

        /// Subscribe to event, use returned 'SubscriberHander' to unsubscribe once finished
        pub fn subscribe(self: *@This(), in_callback: T) SubscriberHandle {
            const new_handle = self.handle_index;
            defer self.handle_index += 1;
            self.subscribers.append(Subscriber{.callback = in_callback, .handle = new_handle}) catch {
                std.debug.print("Error adding sub!\n", .{});
            };
            return new_handle;
        }

        /// Unsubscribes from an event using the SubscriberHandle
        pub fn unsubscribe(self: *@This(), sub_handle: SubscriberHandle) !void {
            var index: usize = 0;
            for (self.subscribers.items) |*sub| {
                if (sub.handle == sub_handle) {
                    _ = self.subscribers.swapRemove(index);
                    break;
                }
                index += 1;
            }
        }

        /// Clears all subscribers
        pub fn clearAndFree(self: *@This()) void {
            self.subscribers.clearAndFree();
        }
    };
}
