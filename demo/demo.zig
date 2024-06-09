const std = @import("std");

const zeika = @import("zeika");
const math = zeika.math;

const Texture = zeika.Texture;
const Font = zeika.Font;
const Renderer = zeika.Renderer;

const embedded_sprite = @embedFile("test_sprite.png");
const embedded_font = @embedFile("verdana.ttf");

pub fn main() !void {
    try zeika.initAll("Zig Test", 800, 600, 800, 600);
    defer zeika.shutdownAll();

    const test_font = Font.initFromMemory(@ptrCast(embedded_font.ptr), embedded_font.len, .{ .font_size = 48 });
    defer test_font.deinit();

    const texture_handle = Texture.initSolidColoredTexture(1, 1, 255);
    defer texture_handle.deinit();

    const test_sprite = Texture.initFromMemory(@ptrCast(embedded_sprite.ptr),  embedded_sprite.len);
    defer test_sprite.deinit();

    while (zeika.isRunning()) {
        zeika.update();

        if (zeika.isKeyJustPressed(zeika.InputKey.keyboard_escape, 0)) {
            break;
        }

        Renderer.queueDrawText(&.{
            .font = test_font,
            .text = "Zeika",
            .position = .{ .x = 300.0, .y = 75.0 }
        });
        Renderer.queueDrawSprite(&.{
            .texture_handle = texture_handle,
            .draw_source = .{ .x = 0.0, .y = 0.0, .w = 1.0, .h = 1.0 },
            .size = .{ .x = 64.0, .y = 64.0 },
            .transform = &.{ .position = .{ .x = 100.0, .y = 100.0 } },
            .color = math.Color.Red,
        });
        Renderer.queueDrawSprite(&.{
            .texture_handle = test_sprite,
            .draw_source = .{ .x = 0.0, .y = 0.0, .w = 64.0, .h = 64.0 },
            .size = .{ .x = 64.0, .y = 64.0 },
            .transform = &.{ .position = .{ .x = 400.0, .y = 300.0 } },
            .color = math.Color.White,
        });

        Renderer.flushBatches();
    }
}
