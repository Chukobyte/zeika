const std = @import("std");

pub fn Vector2(comptime T: type) type {
    return struct {
        x: T,
        y: T,

        pub fn Equals(a: *const Vector2(T), b: *const Vector2(T)) bool {
            return a.x == b.x and a.y == b.y;
        }

        pub fn Add(a: *const Vector2(T), b: *const Vector2(T)) Vector2(T) {
            return @This(){
                .x = a.x + b.x,
                .y = a.y + b.y,
            };
        }

        pub fn Sub(a: *const Vector2(T), b: *const Vector2(T)) Vector2(T) {
            return @This(){
                .x = a.x - b.x,
                .y = a.y - b.y,
            };
        }

        pub fn Div(a: *const Vector2(T), b: *const Vector2(T)) Vector2(T) {
            std.debug.assert(b.x != 0 and b.y != 0);
            return @This(){
                .x = a.x / b.x,
                .y = a.y / b.y,
            };
        }

        pub fn Mult(a: *const Vector2(T), b: *const Vector2(T)) Vector2(T) {
            return @This(){
                .x = a.x * b.x,
                .y = a.y * b.y,
            };
        }
    };
}

pub const Vec2f = Vector2(f32);
pub const Vec2 = Vector2(f32);
pub const Vec2i = Vector2(i32);
pub const Vec2u = Vector2(u32);
