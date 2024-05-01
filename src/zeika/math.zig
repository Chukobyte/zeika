const std = @import("std");

const seika = @cImport({
    @cInclude("seika/math/math.h");
});

// Vector2
pub fn Vector2(comptime T: type) type {
    return struct {
        x: T = @as(T, 0),
        y: T = @as(T, 0),

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

// Transform2D
pub fn Transformation2D(comptime PosT: type, comptime ScaleT: type, comptime RotT: type) type {
    return struct {
        position: Vector2(PosT) = Vector2(PosT){},
        scale: Vector2(ScaleT) = Vector2(ScaleT){ .x = @as(ScaleT, 1), .y = @as(ScaleT, 1) },
        rotation: RotT = @as(RotT, 0),
    };
}

pub const Transform2D = Transformation2D(f32, f32, f32);

// Rect2
// TODO: Think about it we want a separate extents version...
pub fn Rectangle2(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        w: T,
        h: T,
    };
}

pub const Rect2 = Rectangle2(f32);
pub const Rect2f = Rect2;
pub const Rect2i = Rectangle2(i32);
pub const Rect2u = Rectangle2(u32);

// Color
pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255,

    pub const Black = @This(){ .r = 0, .g = 0, .b = 0 };
    pub const White = @This(){ .r = 255, .g = 255, .b = 255 };
    pub const Red = @This(){ .r = 255, .g = 0, .b = 0 };
    pub const Green = @This(){ .r = 0, .g = 255, .b = 0 };
    pub const Blue = @This(){ .r = 0, .g = 0, .b = 255 };

    pub fn ToSkaColor(self: *Color) seika.SkaColor {
        return seika.SkaColor{
            *self.r / 255.0,
            *self.g / 255.0,
            *self.b / 255.0,
            *self.a / 255.0
        };
    }
};

pub const LinearColor = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32 = 1.0,
};
