const std = @import("std");

const seika = @import("seika_includes.zig").seika;

// Vector2
pub fn Vector2(comptime T: type) type {
    return struct {
        x: T = @as(T, 0),
        y: T = @as(T, 0),

        pub fn Equals(a: *const @This(), b: *const @This()) bool {
            return a.x == b.x and a.y == b.y;
        }

        pub fn Add(a: *const @This(), b: *const @This()) @This() {
            return @This(){
                .x = a.x + b.x,
                .y = a.y + b.y,
            };
        }

        pub fn Sub(a: *const @This(), b: *const @This()) @This() {
            return @This(){
                .x = a.x - b.x,
                .y = a.y - b.y,
            };
        }

        pub fn Div(a: *const @This(), b: *const @This()) @This() {
            std.debug.assert(b.x != 0 and b.y != 0);
            return @This(){
                .x = a.x / b.x,
                .y = a.y / b.y,
            };
        }

        pub fn Mult(a: *const @This(), b: *const @This()) @This() {
            return @This(){
                .x = a.x * b.x,
                .y = a.y * b.y,
            };
        }

        pub fn toSkaVector2(self: *const @This()) seika.SkaVector2 {
            return seika.SkaVector2{ .x = @floatCast(self.x), .y = @floatCast(self.y) };
        }

        pub fn toSkaSize2D(self: *const @This()) seika.SkaSize2D {
            return seika.SkaSize2D{ .w = @floatCast(self.x), .h = @floatCast(self.y) };
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

        pub fn toSkaTransform2D(self: *const @This()) seika.SkaTransform2D {
            return seika.SkaTransform2D{
                .position = seika.SkaVector2{ .x = @floatCast(self.position.x), .y = @floatCast(self.position.y) },
                .scale = seika.SkaVector2{ .x = @floatCast(self.scale.x), .y = @floatCast(self.scale.y) },
                .rotation = @floatCast(self.rotation),
            };
        }
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

        pub fn toSkaRect2(self: *const @This()) seika.SkaRect2 {
            return seika.SkaRect2{
                .x = @floatCast(self.x), .y = @floatCast(self.y), .w = @floatCast(self.w), .h = @floatCast(self.h)
            };
        }
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

    pub fn ToSkaColor(self: *const Color) seika.SkaColor {
        const r: f32 = @floatFromInt(self.r);
        const g: f32 = @floatFromInt(self.g);
        const b: f32 = @floatFromInt(self.b);
        const a: f32 = @floatFromInt(self.a);
        return seika.SkaColor{
            .r = r / 255.0,
            .g = g / 255.0,
            .b = b / 255.0,
            .a = a / 255.0
        };
    }
};

pub const LinearColor = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32 = 1.0,
};
