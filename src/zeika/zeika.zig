const std = @import("std");

pub const Math = @import("math.zig");
pub const Event = @import("event.zig");

const seika = @cImport({
    @cInclude("seika/seika.h");
    @cInclude("seika/rendering/texture.h");
    @cInclude("seika/rendering/renderer.h");
    @cInclude("seika/input/input.h");
});

// Seika
pub inline fn init_all(window_title: []const u8, window_width: i32, window_height: i32, resolution_width: i32, resolution_height: i32) !void {
    if (!seika.ska_init_all(&window_title[0], window_width, window_height, resolution_width, resolution_height)) {
        return error.ZeikaInitFailure;
    }
}

pub inline fn shutdown_all() void {
    seika.ska_shutdown_all();
}

pub inline fn update() void {
    seika.ska_update();
}

pub inline fn is_running() bool {
    return seika.ska_is_running();
}

// Rendering
pub const Texture = struct {
    internal_texture: *seika.SkaTexture = undefined,

    pub fn init_solid_colored_texture(width: i32, height: i32, color_value: u32) Texture {
        const texture = seika.ska_texture_create_solid_colored_texture(width, height, color_value);
        return @This(){
            .internal_texture = texture,
        };
    }

    pub fn deinit_texture(texture: *Texture) void {
        seika.ska_texture_delete(texture.internal_texture);
    }
};

pub const Renderer = struct {
    pub fn queue_draw_sprite(texture: *const Texture, source: *const Math.Rect2, size: *const Math.Vec2, color: *const Math.Color, flip_h: bool, flip_v: bool, transform: *const Math.Transform2D, z_index: i32) void {
        const ska_transform = seika.SkaTransform2D{
            .position = seika.SkaVector2{ .x = transform.position.x, .y = transform.position.y },
            .scale = seika.SkaVector2{ .x = transform.scale.x, .y = transform.scale.y },
            .rotation = transform.rotation,
        };
        const r: f32 = @floatFromInt(color.r);
        const g: f32 = @floatFromInt(color.g);
        const b: f32 = @floatFromInt(color.b);
        const a: f32 = @floatFromInt(color.a);
        seika.ska_renderer_queue_sprite_draw(
            texture.internal_texture,
            seika.SkaRect2{ .x = source.x, .y = source.y, .w = source.w, .h = source.h },
            seika.SkaSize2D{ .w = size.x, .h = size.y },
            seika.SkaColor{ .r = 255.0 / r, .g = 255.0 / g, .b = 255.0 / b, .a = 255.0 / a },
            flip_h,
            flip_v,
            &ska_transform,
            z_index,
            null
        );
    }



    pub fn flush_batched_sprites() void {
        seika.ska_window_render();
    }
};

// Input
pub const InputKey = enum(c_uint) {
    INVALID,
    // Gamepad
    GAMEPAD_DPAD_DOWN,
    GAMEPAD_DPAD_UP,
    GAMEPAD_DPAD_LEFT,
    GAMEPAD_DPAD_RIGHT,
    GAMEPAD_FACE_BUTTON_NORTH,  // XBOX Y
    GAMEPAD_FACE_BUTTON_SOUTH,  // XBOX A
    GAMEPAD_FACE_BUTTON_EAST,   // XBOX B
    GAMEPAD_FACE_BUTTON_WEST,   // XBOX X
    GAMEPAD_START,
    GAMEPAD_BACK,
    GAMEPAD_LEFT_SHOULDER,      // PS L1
    GAMEPAD_LEFT_TRIGGER,       // PS L2
    GAMEPAD_LEFT_ANALOG_BUTTON, // PS L3
    GAMEPAD_LEFT_ANALOG_2D_AXIS_X,
    GAMEPAD_LEFT_ANALOG_2D_AXIS_Y,
    GAMEPAD_RIGHT_SHOULDER,      // PS R1
    GAMEPAD_RIGHT_TRIGGER,       // PS R2
    GAMEPAD_RIGHT_ANALOG_BUTTON, // PS R3
    GAMEPAD_RIGHT_ANALOG_2D_AXIS_X,
    GAMEPAD_RIGHT_ANALOG_2D_AXIS_Y,
    GAMEPAD_LEFT_ANALOG_LEFT,
    GAMEPAD_LEFT_ANALOG_RIGHT,
    GAMEPAD_LEFT_ANALOG_UP,
    GAMEPAD_LEFT_ANALOG_DOWN,
    GAMEPAD_RIGHT_ANALOG_LEFT,
    GAMEPAD_RIGHT_ANALOG_RIGHT,
    GAMEPAD_RIGHT_ANALOG_UP,
    GAMEPAD_RIGHT_ANALOG_DOWN,
    // Keyboard
    KEYBOARD_TAB,
    KEYBOARD_LEFT,
    KEYBOARD_RIGHT,
    KEYBOARD_UP,
    KEYBOARD_DOWN,
    KEYBOARD_PAGE_DOWN,
    KEYBOARD_PAGE_UP,
    KEYBOARD_HOME,
    KEYBOARD_END,
    KEYBOARD_INSERT,
    KEYBOARD_DELETE,
    KEYBOARD_BACKSPACE,
    KEYBOARD_SPACE,
    KEYBOARD_RETURN,
    KeyboardEscape,
    KEYBOARD_QUOTE,
    KEYBOARD_COMMA,
    KEYBOARD_MINUS,
    KEYBOARD_PERIOD,
    KEYBOARD_SLASH,
    KEYBOARD_SEMICOLON,
    KEYBOARD_EQUALS,
    KEYBOARD_LEFT_BRACKET,
    KEYBOARD_RIGHT_BRACKET,
    KEYBOARD_BACKSLASH,
    KEYBOARD_BACKQUOTE,
    KEYBOARD_CAPS_LOCK,
    KEYBOARD_SCROLL_LOCK,
    KEYBOARD_NUM_LOCK_CLEAR,
    KEYBOARD_PRINT_SCREEN,
    KEYBOARD_PAUSE,
    KEYBOARD_KEYPAD_0,
    KEYBOARD_KEYPAD_1,
    KEYBOARD_KEYPAD_2,
    KEYBOARD_KEYPAD_3,
    KEYBOARD_KEYPAD_4,
    KEYBOARD_KEYPAD_5,
    KEYBOARD_KEYPAD_6,
    KEYBOARD_KEYPAD_7,
    KEYBOARD_KEYPAD_8,
    KEYBOARD_KEYPAD_9,
    KEYBOARD_KEYPAD_PERIOD,
    KEYBOARD_KEYPAD_DIVIDE,
    KEYBOARD_KEYPAD_MULTIPLY,
    KEYBOARD_KEYPAD_MINUS,
    KEYBOARD_KEYPAD_PLUS,
    KEYBOARD_KEYPAD_ENTER,
    KEYBOARD_KEYPAD_EQUALS,
    KEYBOARD_LEFT_CONTROL,
    KEYBOARD_LEFT_SHIFT,
    KEYBOARD_LEFT_ALT,
    KEYBOARD_LEFT_GUI,
    KEYBOARD_RIGHT_CONTROL,
    KEYBOARD_RIGHT_SHIFT,
    KEYBOARD_RIGHT_ALT,
    KEYBOARD_RIGHT_GUI,
    KEYBOARD_APPLICATION,
    KEYBOARD_NUM_0,
    KEYBOARD_NUM_1,
    KEYBOARD_NUM_2,
    KEYBOARD_NUM_3,
    KEYBOARD_NUM_4,
    KEYBOARD_NUM_5,
    KEYBOARD_NUM_6,
    KEYBOARD_NUM_7,
    KEYBOARD_NUM_8,
    KEYBOARD_NUM_9,
    KEYBOARD_A,
    KEYBOARD_B,
    KEYBOARD_C,
    KEYBOARD_D,
    KEYBOARD_E,
    KEYBOARD_F,
    KEYBOARD_G,
    KEYBOARD_H,
    KEYBOARD_I,
    KEYBOARD_J,
    KEYBOARD_K,
    KEYBOARD_L,
    KEYBOARD_M,
    KEYBOARD_N,
    KEYBOARD_O,
    KEYBOARD_P,
    KEYBOARD_Q,
    KEYBOARD_R,
    KEYBOARD_S,
    KEYBOARD_T,
    KEYBOARD_U,
    KEYBOARD_V,
    KEYBOARD_W,
    KEYBOARD_X,
    KEYBOARD_Y,
    KEYBOARD_Z,
    KEYBOARD_F1,
    KEYBOARD_F2,
    KEYBOARD_F3,
    KEYBOARD_F4,
    KEYBOARD_F5,
    KEYBOARD_F6,
    KEYBOARD_F7,
    KEYBOARD_F8,
    KEYBOARD_F9,
    KEYBOARD_F10,
    KEYBOARD_F11,
    KEYBOARD_F12,
    KEYBOARD_F13,
    KEYBOARD_F14,
    KEYBOARD_F15,
    KEYBOARD_F16,
    KEYBOARD_F17,
    KEYBOARD_F18,
    KEYBOARD_F19,
    KEYBOARD_F20,
    KEYBOARD_F21,
    KEYBOARD_F22,
    KEYBOARD_F23,
    KEYBOARD_F24,
    KEYBOARD_APP_FORWARD,
    KEYBOARD_APP_BACK,
    // Mouse
    MOUSE_BUTTON_LEFT,
    MOUSE_BUTTON_RIGHT,
    MOUSE_BUTTON_MIDDLE,
};

pub inline fn is_key_just_pressed(key: InputKey, device_index: seika.SkaInputDeviceIndex) bool {
    return seika.ska_input_is_key_just_pressed(@intFromEnum(key), device_index);
}
