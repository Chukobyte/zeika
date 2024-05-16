const std = @import("std");

pub const seika = @import("seika_includes.zig").seika;

pub const math = @import("math.zig");
pub const event = @import("event.zig");

// Seika
pub inline fn initAll(window_title: []const u8, window_width: i32, window_height: i32, resolution_width: i32, resolution_height: i32) !void {
    if (!seika.ska_init_all(&window_title[0], window_width, window_height, resolution_width, resolution_height)) {
        return error.ZeikaInitFailure;
    }
}

pub inline fn shutdownAll() void {
    seika.ska_shutdown_all();
}

pub inline fn update() void {
    seika.ska_update();
}

pub inline fn isRunning() bool {
    return seika.ska_is_running();
}

// Rendering
pub const Texture = struct {

    pub const Handle = struct {
        internal_texture: [*c]seika.SkaTexture = undefined,
    };

    pub fn initSolidColoredTexture(width: i32, height: i32, color_value: u32) Handle {
        const texture = seika.ska_texture_create_solid_colored_texture(width, height, color_value);
        return Handle{
            .internal_texture = texture,
        };
    }

    pub fn initFromMemory(buffer: *anyopaque, buffer_len: usize) Handle {
        const texture = seika.ska_texture_create_from_memory(buffer, buffer_len);
        return Handle{
            .internal_texture = texture,
        };
    }

    pub fn deinit(texture: Handle) void {
        seika.ska_texture_delete(texture.internal_texture);
    }
};

pub const Font = struct {
    internal_font: [*c]seika.SkaFont,

    pub const InitParams = struct {
        font_size: i32 = 16,
        apply_nearest_neighbor: bool = true,
    };

    pub fn initFromMemory(buffer: *anyopaque, buffer_len: usize, init_params: InitParams) @This() {
        const new_font = Font{
            .internal_font = seika.ska_font_create_font_from_memory(buffer, buffer_len, init_params.font_size, init_params.apply_nearest_neighbor)
        };
        return new_font;
    }

    pub fn deinit(self: *const @This()) void {
        seika.ska_font_delete(self.internal_font);
    }
};

pub const Renderer = struct {
    pub const SpriteDrawQueueConfig = struct {
        texture_handle: Texture.Handle,
        draw_source: math.Rect2,
        size: math.Vec2,
        transform: *const math.Transform2D,
        color: math.Color = math.Color.White,
        flip_h: bool = false,
        flip_v: bool = false,
        z_index: i32 = 0,
    };

    pub const TextDrawQueueConfig = struct {
        font: Font,
        text: []const u8,
        position: math.Vec2,
        scale: f32 = 1.0,
        color: math.Color = math.Color.White,
        z_index: i32 = 0,
    };

    pub fn queueDrawSprite(draw_config: *const SpriteDrawQueueConfig) void {
        const source_rect: seika.SkaRect2 = draw_config.draw_source.toSkaRect2();
        seika.ska_renderer_queue_sprite_draw(
            draw_config.texture_handle.internal_texture,
            source_rect,
            draw_config.size.toSkaSize2D(),
            draw_config.color.toSkaColor(),
            draw_config.flip_h,
            draw_config.flip_v,
            &draw_config.transform.toSkaTransform2D(),
            draw_config.z_index,
            null // We don't have a shader instance api in zig yet
        );
    }

    pub fn queueDrawText(draw_config: *const TextDrawQueueConfig) void {
        seika.ska_renderer_queue_font_draw_call(
            draw_config.font.internal_font,
            &draw_config.text[0],
            draw_config.position.x,
            draw_config.position.y,
            draw_config.scale,
            draw_config.color.toSkaColor(),
            draw_config.z_index
        );
    }

    pub fn flushBatches() void {
        seika.ska_window_render();
    }
};

// Input
pub const InputKey = enum(c_uint) {
    invalid,
    // Gamepad
    gamepad_dpad_down,
    gamepad_dpad_up,
    gamepad_dpad_left,
    gamepad_dpad_right,
    gamepad_face_button_north,  // xbox y
    gamepad_face_button_south,  // xbox a
    gamepad_face_button_east,   // xbox b
    gamepad_face_button_west,   // xbox x
    gamepad_start,
    gamepad_back,
    gamepad_left_shoulder,      // ps l1
    gamepad_left_trigger,       // ps l2
    gamepad_left_analog_button, // ps l3
    gamepad_left_analog_2d_axis_x,
    gamepad_left_analog_2d_axis_y,
    gamepad_right_shoulder,      // ps r1
    gamepad_right_trigger,       // ps r2
    gamepad_right_analog_button, // ps r3
    gamepad_right_analog_2d_axis_x,
    gamepad_right_analog_2d_axis_y,
    gamepad_left_analog_left,
    gamepad_left_analog_right,
    gamepad_left_analog_up,
    gamepad_left_analog_down,
    gamepad_right_analog_left,
    gamepad_right_analog_right,
    gamepad_right_analog_up,
    gamepad_right_analog_down,
    // Keyboard
    keyboard_tab,
    keyboard_left,
    keyboard_right,
    keyboard_up,
    keyboard_down,
    keyboard_page_down,
    keyboard_page_up,
    keyboard_home,
    keyboard_end,
    keyboard_insert,
    keyboard_delete,
    keyboard_backspace,
    keyboard_space,
    keyboard_return,
    keyboard_escape,
    keyboard_quote,
    keyboard_comma,
    keyboard_minus,
    keyboard_period,
    keyboard_slash,
    keyboard_semicolon,
    keyboard_equals,
    keyboard_left_bracket,
    keyboard_right_bracket,
    keyboard_backslash,
    keyboard_backquote,
    keyboard_caps_lock,
    keyboard_scroll_lock,
    keyboard_num_lock_clear,
    keyboard_print_screen,
    keyboard_pause,
    keyboard_keypad_0,
    keyboard_keypad_1,
    keyboard_keypad_2,
    keyboard_keypad_3,
    keyboard_keypad_4,
    keyboard_keypad_5,
    keyboard_keypad_6,
    keyboard_keypad_7,
    keyboard_keypad_8,
    keyboard_keypad_9,
    keyboard_keypad_period,
    keyboard_keypad_divide,
    keyboard_keypad_multiply,
    keyboard_keypad_minus,
    keyboard_keypad_plus,
    keyboard_keypad_enter,
    keyboard_keypad_equals,
    keyboard_left_control,
    keyboard_left_shift,
    keyboard_left_alt,
    keyboard_left_gui,
    keyboard_right_control,
    keyboard_right_shift,
    keyboard_right_alt,
    keyboard_right_gui,
    keyboard_application,
    keyboard_num_0,
    keyboard_num_1,
    keyboard_num_2,
    keyboard_num_3,
    keyboard_num_4,
    keyboard_num_5,
    keyboard_num_6,
    keyboard_num_7,
    keyboard_num_8,
    keyboard_num_9,
    keyboard_a,
    keyboard_b,
    keyboard_c,
    keyboard_d,
    keyboard_e,
    keyboard_f,
    keyboard_g,
    keyboard_h,
    keyboard_i,
    keyboard_j,
    keyboard_k,
    keyboard_l,
    keyboard_m,
    keyboard_n,
    keyboard_o,
    keyboard_p,
    keyboard_q,
    keyboard_r,
    keyboard_s,
    keyboard_t,
    keyboard_u,
    keyboard_v,
    keyboard_w,
    keyboard_x,
    keyboard_y,
    keyboard_z,
    keyboard_f1,
    keyboard_f2,
    keyboard_f3,
    keyboard_f4,
    keyboard_f5,
    keyboard_f6,
    keyboard_f7,
    keyboard_f8,
    keyboard_f9,
    keyboard_f10,
    keyboard_f11,
    keyboard_f12,
    keyboard_f13,
    keyboard_f14,
    keyboard_f15,
    keyboard_f16,
    keyboard_f17,
    keyboard_f18,
    keyboard_f19,
    keyboard_f20,
    keyboard_f21,
    keyboard_f22,
    keyboard_f23,
    keyboard_f24,
    keyboard_app_forward,
    keyboard_app_back,
    // mouse
    mouse_button_left,
    mouse_button_right,
    mouse_button_middle,
};

pub inline fn isKeyJustPressed(key: InputKey, device_index: seika.SkaInputDeviceIndex) bool {
    return seika.ska_input_is_key_just_pressed(@intFromEnum(key), device_index);
}

pub inline fn getMousePosition() math.Vec2 {
    const globalMouse: [*c]seika.SkaMouse = seika.ska_input_get_mouse();
    return math.Vec2{ .x = globalMouse.*.position.x, .y = globalMouse.*.position.y };
}

pub fn getWindowSize() math.Vec2i {
    const render_context: [*c]seika.SkaRenderContext = seika.ska_render_context_get();
    return math.Vec2i{
        .x = render_context.*.windowWidth,
        .y = render_context.*.windowHeight
    };
}
