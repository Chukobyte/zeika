const std = @import("std");

const deps_path = "deps";

const sdl_dep_path = deps_path ++ "/SDL-release-2.30.2";
const sdl_include_path = sdl_dep_path ++ "/include";

const zlib_dep_path = deps_path ++ "/zlib";

const libpng_dep_path = deps_path ++ "/libpng";

const ft_dep_path = deps_path ++ "/freetype-VER-2-13-2";
const ft_include_path = ft_dep_path ++ "/include";

const cglm_dep_path = deps_path ++ "/cglm";
const cglm_include_path = cglm_dep_path ++ "/include";

const kuba_zip_dep_path = deps_path ++ "/kuba_zip";
const kuba_zip_include_path = kuba_zip_dep_path ++ "/src";

const stb_image_dep_path = deps_path ++ "/stb_image";
const stb_image_include_path = stb_image_dep_path;

const glad_dep_path = deps_path ++ "/glad";
const glad_include_path = deps_path;

const seika_dep_path = deps_path ++ "/seika";
const seika_include_path = deps_path;

/// Only tested for 'x86_64-windows-gnu'
pub fn build(b: *std.Build) !void {
    const target: std.Build.ResolvedTarget = b.standardTargetOptions(.{});
    const optimize: std.builtin.OptimizeMode = b.standardOptimizeOption(.{});

    const create_demo: bool = b.option(bool, "create_demo", "Will create a demo executable") orelse false;

    const exe: *std.Build.Step.Compile = b.addExecutable(.{
        .name = "main",
        .root_source_file = .{ .path = "src/demo.zig" },
        .target = target,
        .optimize = optimize,
    });

    // Dependencies
    const seika_lib: *std.Build.Step.Compile = try add_seika(b, target, optimize);

    const zeika_mod = b.addModule("zeika", .{
        .root_source_file = .{ .path = "src/zeika/zeika.zig" },
    });
    zeika_mod.linkLibrary(seika_lib);

    if (create_demo) {
        exe.linkLibC();
        exe.root_module.addImport("zeika", zeika_mod);
        exe.linkLibrary(seika_lib);

        b.installArtifact(exe);

        const run_exe: *std.Build.Step.Run = b.addRunArtifact(exe);
        const run_step: *std.Build.Step = b.step("run", "Run the application");
        run_step.dependOn(&run_exe.step);
    }
}

fn add_sdl(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !*std.Build.Step.Compile {
    const sdl_lib: *std.Build.Step.Compile = b.addStaticLibrary(.{
        .name = "SDL3",
        .target = target,
        .optimize = optimize,
    });

    sdl_lib.addIncludePath(.{ .path = sdl_include_path });
    sdl_lib.addIncludePath(.{ .path = sdl_dep_path ++ "/src" });
    sdl_lib.addCSourceFiles(.{ .files = &sdl_generic_src_files });
    sdl_lib.defineCMacro("SDL_DYNAMIC_API", "0");
    sdl_lib.defineCMacro("SDL_USE_BUILTIN_OPENGL_DEFINITIONS", "1");
    sdl_lib.linkLibC();
    switch (target.result.os.tag) {
        .windows => {
            sdl_lib.defineCMacro("HAVE_MODF", "1");
            sdl_lib.addCSourceFiles(.{ .files = &sdl_windows_src_files });
            sdl_lib.linkSystemLibrary("setupapi");
            sdl_lib.linkSystemLibrary("winmm");
            sdl_lib.linkSystemLibrary("gdi32");
            sdl_lib.linkSystemLibrary("imm32");
            sdl_lib.linkSystemLibrary("version");
            sdl_lib.linkSystemLibrary("oleaut32");
            sdl_lib.linkSystemLibrary("ole32");
        },
    // .macos => {
    //     sdl_lib.addCSourceFiles(.{ .files = &darwin_src_files });
    //     sdl_lib.addCSourceFiles(.{
    //         .files = &objective_c_src_files,
    //         .flags = &.{"-fobjc-arc"},
    //     });
    //     sdl_lib.linkFramework("OpenGL");
    //     sdl_lib.linkFramework("Metal");
    //     sdl_lib.linkFramework("CoreVideo");
    //     sdl_lib.linkFramework("Cocoa");
    //     sdl_lib.linkFramework("IOKit");
    //     sdl_lib.linkFramework("ForceFeedback");
    //     sdl_lib.linkFramework("Carbon");
    //     sdl_lib.linkFramework("Carbon");
    //     sdl_lib.linkFramework("CoreAudio");
    //     sdl_lib.linkFramework("AudioToolbox");
    //     sdl_lib.linkFramework("AVFoundation");
    //     sdl_lib.linkFramework("Foundation");
    // },
        else => {
            unreachable;
            // const config_header = b.addConfigHeader(.{
            //     .style = .{ .cmake = .{ .path = "include/SDL_config.h.cmake" } },
            //     .include_path = "SDL2/SDL_config.h",
            // }, .{});
            // sdl_lib.addConfigHeader(config_header);
            // sdl_lib.installConfigHeader(config_header, .{});
        },
    }

    sdl_lib.installHeadersDirectory(sdl_include_path, "SDL3");
    b.installArtifact(sdl_lib);

    return sdl_lib;
}

fn add_freetype(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !*std.Build.Step.Compile {
    // Build zlib
    const zlib_src_dir = zlib_dep_path ++ "/src";
    const zlib_lib: *std.Build.Step.Compile = b.addStaticLibrary(.{
        .name = "z",
        .target = target,
        .optimize = optimize,
    });
    zlib_lib.linkLibC();
    zlib_lib.addIncludePath(.{ .path = zlib_src_dir });
    zlib_lib.installHeadersDirectoryOptions(.{
        .source_dir = .{ .path = zlib_src_dir },
        .install_dir = .header,
        .install_subdir = "",
        .exclude_extensions = &.{ ".c", ".in", ".txt" },
    });

    var zlib_flags = std.ArrayList([]const u8).init(b.allocator);
    defer zlib_flags.deinit();
    try zlib_flags.appendSlice(&.{
        "-DHAVE_SYS_TYPES_H",
        "-DHAVE_STDINT_H",
        "-DHAVE_STDDEF_H",
        "-DZ_HAVE_UNISTD_H",
        });
    zlib_lib.addCSourceFiles(.{ .files = &zlib_srcs, .flags = zlib_flags.items });

    b.installArtifact(zlib_lib);

    // Build libpng
    const libpng_lib: *std.Build.Step.Compile = b.addStaticLibrary(.{
        .name = "png",
        .target = target,
        .optimize = optimize,
    });
    libpng_lib.linkLibC();
    if (target.result.os.tag == std.Target.Os.Tag.linux) {
        libpng_lib.linkSystemLibrary("m");
    }

    libpng_lib.linkLibrary(zlib_lib);
    libpng_lib.addIncludePath(.{ .path = libpng_dep_path ++ "/include" });
    libpng_lib.addIncludePath(.{ .path = libpng_dep_path ++ "/src" });

    var libpng_flags = std.ArrayList([]const u8).init(b.allocator);
    defer libpng_flags.deinit();
    try libpng_flags.appendSlice(&.{
        "-DPNG_ARM_NEON_OPT=0",
        "-DPNG_POWERPC_VSX_OPT=0",
        "-DPNG_INTEL_SSE_OPT=0",
        "-DPNG_MIPS_MSA_OPT=0",
    });
    libpng_lib.addCSourceFiles(.{ .files = &libpng_srcs, .flags = libpng_flags.items });

    libpng_lib.installHeader(libpng_dep_path ++ "/include/pnglibconf.h", "pnglibconf.h");
    inline for (libpng_headers) |header| {
        libpng_lib.installHeader(libpng_dep_path ++ "/src/" ++ header, header);
    }

    b.installArtifact(libpng_lib);

    // Build freetype
    const ft_lib: *std.Build.Step.Compile = b.addStaticLibrary(.{
        .name = "freetype",
        .target = target,
        .optimize = optimize,
    });

    ft_lib.linkLibC();
    if (target.result.os.tag == std.Target.Os.Tag.linux) {
        ft_lib.linkSystemLibrary("m");
    }
    ft_lib.linkLibrary(zlib_lib);
    ft_lib.linkLibrary(libpng_lib);

    ft_lib.addIncludePath(.{ .path = ft_include_path });
    ft_lib.defineCMacro("FT_BUILD_LIBRARY", "1");

    var flags = std.ArrayList([]const u8).init(b.allocator);
    defer flags.deinit();
    try flags.appendSlice(&.{
        "-DFT2_BUILD_LIBRARY",

        "-DFT_CONFIG_OPTION_SYSTEM_ZLIB=1",

        "-DHAVE_UNISTD_H",
        "-DHAVE_FCNTL_H",

        "-fno-sanitize=undefined",

        "-DFT_CONFIG_OPTION_USE_PNG=1",
    });

    const ft_build_path = ft_dep_path ++ "/builds";
    switch (target.result.os.tag) {
        .windows => {
            ft_lib.addCSourceFile(.{ .file = .{ .path = ft_dep_path ++ "/src/base/fterrors.c" }, .flags = flags.items });
            ft_lib.addCSourceFile(.{ .file = .{ .path = ft_build_path ++ "/windows/ftdebug.c" }, .flags = flags.items });
            ft_lib.addCSourceFile(.{ .file = .{ .path = ft_build_path ++ "/windows/ftsystem.c" }, .flags = flags.items });
            ft_lib.addWin32ResourceFile(.{ .file = .{ .path = ft_dep_path ++ "/src/base/ftver.rc" } });

        },
        .linux => {
            ft_lib.addCSourceFile(.{ .file = .{ .path = ft_build_path ++ "/unix/ftsystem.c" }, .flags = flags.items });
            ft_lib.addCSourceFile(.{ .file = .{ .path = ft_dep_path ++ "/src/base/ftdebug.c" }, .flags = flags.items });
        },
        else => {
            ft_lib.addCSourceFile(.{ .file = .{ .path = ft_dep_path ++ "/src/base/ftsystem.c" }, .flags = flags.items });
            ft_lib.addCSourceFile(.{ .file = .{ .path = ft_dep_path ++ "/src/base/ftdebug.c" }, .flags = flags.items });
        },
    }

    ft_lib.addCSourceFiles(.{ .files = &ft_srcs, .flags = flags.items });

    ft_lib.installHeadersDirectory(ft_include_path, ".");
    b.installArtifact(ft_lib);

    return ft_lib;
}

fn add_cglm(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !*std.Build.Step.Compile {
    const cglm_lib: *std.Build.Step.Compile = b.addStaticLibrary(.{
        .name = "cglm",
        .target = target,
        .optimize = optimize,
    });

    cglm_lib.addIncludePath(.{ .path = cglm_include_path });
    cglm_lib.addCSourceFiles(.{ .files = &cglm_srcs });
    cglm_lib.defineCMacro("CGLM_STATIC", "1");
    cglm_lib.linkLibC();

    cglm_lib.installHeadersDirectory(cglm_include_path, ".");
    b.installArtifact(cglm_lib);

    return cglm_lib;
}

fn add_kuba_zip(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !*std.Build.Step.Compile {
    const zip_lib: *std.Build.Step.Compile = b.addStaticLibrary(.{
        .name = "zip",
        .target = target,
        .optimize = optimize,
    });

    zip_lib.addIncludePath(.{ .path = kuba_zip_include_path });
    zip_lib.addCSourceFile(.{ .file = .{ .path = kuba_zip_dep_path ++ "/src/zip.c" } });

    zip_lib.linkLibC();

    zip_lib.installHeadersDirectory(kuba_zip_include_path, ".");
    b.installArtifact(zip_lib);

    return zip_lib;
}

fn add_stb_image(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !*std.Build.Step.Compile {
    const stb_image_lib: *std.Build.Step.Compile = b.addStaticLibrary(.{
        .name = "stb_image",
        .target = target,
        .optimize = optimize,
    });

    stb_image_lib.addIncludePath(.{ .path = stb_image_include_path });
    stb_image_lib.addCSourceFile(.{ .file = .{ .path = stb_image_dep_path ++ "/stb_image.c" } });

    stb_image_lib.linkLibC();

    stb_image_lib.installHeader(stb_image_include_path ++ "/stb_image.h", "stb_image/stb_image.h");
    b.installArtifact(stb_image_lib);

    return stb_image_lib;
}

fn add_glad(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !*std.Build.Step.Compile {
    const glad_lib: *std.Build.Step.Compile = b.addStaticLibrary(.{
        .name = "glad",
        .target = target,
        .optimize = optimize,
    });

    glad_lib.addIncludePath(.{ .path = glad_include_path });
    glad_lib.addCSourceFile(.{ .file = .{ .path = glad_dep_path ++ "/glad.c" } });

    glad_lib.linkLibC();

    glad_lib.installHeader(glad_include_path ++ "/glad/glad.h", "glad/glad.h");
    b.installArtifact(glad_lib);

    return glad_lib;
}

fn add_seika(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !*std.Build.Step.Compile {
    const seika_lib: *std.Build.Step.Compile = b.addStaticLibrary(.{
        .name = "seika",
        .target = target,
        .optimize = optimize,
    });

    seika_lib.addIncludePath(.{ .path = seika_include_path });
    seika_lib.addIncludePath(.{ .path = sdl_include_path });
    seika_lib.addCSourceFiles(.{ .files = &seika_srcs });

    seika_lib.linkLibC();
    switch (target.result.os.tag) {
        .windows => {
            seika_lib.linkSystemLibrary("ws2_32");
        },
        .linux => {
            seika_lib.linkSystemLibrary("m");
        },
        .macos => {
            seika_lib.linkSystemLibrary("m");
        },
        else => {},
    }

    const sdl_lib: *std.Build.Step.Compile = try add_sdl(b, target, optimize);
    const ft_lib: *std.Build.Step.Compile = try add_freetype(b, target, optimize);
    const cglm_lib: *std.Build.Step.Compile = try add_cglm(b, target, optimize);
    const kuba_zip_lib: *std.Build.Step.Compile = try add_kuba_zip(b, target, optimize);
    const glad_lib: *std.Build.Step.Compile = try add_glad(b, target, optimize);
    const stb_image_lib: *std.Build.Step.Compile = try add_stb_image(b, target, optimize);
    seika_lib.linkLibrary(sdl_lib);
    seika_lib.linkLibrary(ft_lib);
    seika_lib.linkLibrary(cglm_lib);
    seika_lib.linkLibrary(kuba_zip_lib);
    seika_lib.linkLibrary(glad_lib);
    seika_lib.linkLibrary(stb_image_lib);

    seika_lib.installHeadersDirectory(seika_include_path, ".");
    // seika_lib.installLibraryHeaders(sdl_lib);
    // seika_lib.installLibraryHeaders(ft_lib);
    // seika_lib.installLibraryHeaders(cglm_lib);
    // seika_lib.installLibraryHeaders(kuba_zip_lib);
    // seika_lib.installLibraryHeaders(glad_lib);
    // seika_lib.installLibraryHeaders(stb_image_lib);
    seika_lib.installHeader(deps_path ++ "/miniaudio/miniaudio.h", "miniaudio.h");

    b.installArtifact(seika_lib);

    return seika_lib;
}

const sdl_generic_src_files = [_][]const u8{
    sdl_dep_path ++ "/src/SDL.c",
    sdl_dep_path ++ "/src/SDL_assert.c",
    // sdl_dep_path ++ "/src/SDL_dataqueue.c",
    sdl_dep_path ++ "/src/SDL_error.c",
    sdl_dep_path ++ "/src/SDL_guid.c",
    sdl_dep_path ++ "/src/SDL_hashtable.c",
    sdl_dep_path ++ "/src/SDL_hints.c",
    sdl_dep_path ++ "/src/SDL_list.c",
    sdl_dep_path ++ "/src/SDL_log.c",
    sdl_dep_path ++ "/src/SDL_properties.c",
    sdl_dep_path ++ "/src/SDL_utils.c",
    sdl_dep_path ++ "/src/atomic/SDL_atomic.c",
    sdl_dep_path ++ "/src/atomic/SDL_spinlock.c",
    sdl_dep_path ++ "/src/audio/SDL_audio.c",
    sdl_dep_path ++ "/src/audio/SDL_audiocvt.c",
    sdl_dep_path ++ "/src/audio/SDL_audiodev.c",
    sdl_dep_path ++ "/src/audio/SDL_audioqueue.c",
    sdl_dep_path ++ "/src/audio/SDL_audioresample.c",
    sdl_dep_path ++ "/src/audio/SDL_audiotypecvt.c",
    sdl_dep_path ++ "/src/audio/SDL_mixer.c",
    sdl_dep_path ++ "/src/audio/SDL_wave.c",
    sdl_dep_path ++ "/src/camera/SDL_camera.c",
    sdl_dep_path ++ "/src/camera/dummy/SDL_camera_dummy.c",
    sdl_dep_path ++ "/src/camera/mediafoundation/SDL_camera_mediafoundation.c",
    sdl_dep_path ++ "/src/cpuinfo/SDL_cpuinfo.c",
    sdl_dep_path ++ "/src/dynapi/SDL_dynapi.c",
    sdl_dep_path ++ "/src/events/SDL_clipboardevents.c",
    sdl_dep_path ++ "/src/events/SDL_displayevents.c",
    sdl_dep_path ++ "/src/events/SDL_dropevents.c",
    sdl_dep_path ++ "/src/events/SDL_events.c",
    // sdl_dep_path ++ "/src/events/SDL_gesture.c",
    sdl_dep_path ++ "/src/events/SDL_keyboard.c",
    sdl_dep_path ++ "/src/events/SDL_keysym_to_scancode.c",
    sdl_dep_path ++ "/src/events/SDL_mouse.c",
    sdl_dep_path ++ "/src/events/SDL_pen.c",
    sdl_dep_path ++ "/src/events/SDL_quit.c",
    sdl_dep_path ++ "/src/events/SDL_scancode_tables.c",
    sdl_dep_path ++ "/src/events/SDL_touch.c",
    sdl_dep_path ++ "/src/events/SDL_windowevents.c",
    sdl_dep_path ++ "/src/events/imKStoUCS.c",
    // sdl_dep_path ++ "/src/file/SDL_rwops.c",
    sdl_dep_path ++ "/src/file/SDL_iostream.c",
    sdl_dep_path ++ "/src/haptic/SDL_haptic.c",
    sdl_dep_path ++ "/src/hidapi/SDL_hidapi.c",

    // sdl_dep_path ++ "/src/joystick/SDL_gamecontroller.c",
    sdl_dep_path ++ "/src/joystick/SDL_joystick.c",
    sdl_dep_path ++ "/src/joystick/SDL_gamepad.c",
    sdl_dep_path ++ "/src/joystick/controller_type.c",
    sdl_dep_path ++ "/src/joystick/SDL_steam_virtual_gamepad.c",
    sdl_dep_path ++ "/src/joystick/virtual/SDL_virtualjoystick.c",

    // sdl_dep_path ++ "/src/filesystem/SDL_filesystem.c",
    sdl_dep_path ++ "/src/libm/e_atan2.c",
    sdl_dep_path ++ "/src/libm/e_exp.c",
    sdl_dep_path ++ "/src/libm/e_fmod.c",
    sdl_dep_path ++ "/src/libm/e_log.c",
    sdl_dep_path ++ "/src/libm/e_log10.c",
    sdl_dep_path ++ "/src/libm/e_pow.c",
    sdl_dep_path ++ "/src/libm/e_rem_pio2.c",
    sdl_dep_path ++ "/src/libm/e_sqrt.c",
    sdl_dep_path ++ "/src/libm/k_cos.c",
    sdl_dep_path ++ "/src/libm/k_rem_pio2.c",
    sdl_dep_path ++ "/src/libm/k_sin.c",
    sdl_dep_path ++ "/src/libm/k_tan.c",
    sdl_dep_path ++ "/src/libm/s_atan.c",
    sdl_dep_path ++ "/src/libm/s_copysign.c",
    sdl_dep_path ++ "/src/libm/s_cos.c",
    sdl_dep_path ++ "/src/libm/s_fabs.c",
    sdl_dep_path ++ "/src/libm/s_floor.c",
    sdl_dep_path ++ "/src/libm/s_scalbn.c",
    sdl_dep_path ++ "/src/libm/s_sin.c",
    sdl_dep_path ++ "/src/libm/s_tan.c",
    sdl_dep_path ++ "/src/locale/SDL_locale.c",
    sdl_dep_path ++ "/src/main/SDL_main_callbacks.c",
    sdl_dep_path ++ "/src/misc/SDL_url.c",
    sdl_dep_path ++ "/src/power/SDL_power.c",
    sdl_dep_path ++ "/src/render/SDL_d3dmath.c",
    sdl_dep_path ++ "/src/render/SDL_render.c",
    sdl_dep_path ++ "/src/render/SDL_yuv_sw.c",
    sdl_dep_path ++ "/src/sensor/SDL_sensor.c",
    sdl_dep_path ++ "/src/stdlib/SDL_crc16.c",
    sdl_dep_path ++ "/src/stdlib/SDL_crc32.c",
    sdl_dep_path ++ "/src/stdlib/SDL_getenv.c",
    sdl_dep_path ++ "/src/stdlib/SDL_iconv.c",
    sdl_dep_path ++ "/src/stdlib/SDL_malloc.c",
    sdl_dep_path ++ "/src/stdlib/SDL_memcpy.c",
    sdl_dep_path ++ "/src/stdlib/SDL_memmove.c",
    sdl_dep_path ++ "/src/stdlib/SDL_memset.c",
    sdl_dep_path ++ "/src/stdlib/SDL_mslibc.c",
    sdl_dep_path ++ "/src/stdlib/SDL_qsort.c",
    sdl_dep_path ++ "/src/stdlib/SDL_stdlib.c",
    sdl_dep_path ++ "/src/stdlib/SDL_string.c",
    sdl_dep_path ++ "/src/stdlib/SDL_strtokr.c",
    sdl_dep_path ++ "/src/thread/SDL_thread.c",
    sdl_dep_path ++ "/src/thread/generic/SDL_sysrwlock.c",
    sdl_dep_path ++ "/src/time/SDL_time.c",
    sdl_dep_path ++ "/src/timer/SDL_timer.c",
    sdl_dep_path ++ "/src/video/SDL_RLEaccel.c",
    sdl_dep_path ++ "/src/video/SDL_blit.c",
    sdl_dep_path ++ "/src/video/SDL_blit_0.c",
    sdl_dep_path ++ "/src/video/SDL_blit_1.c",
    sdl_dep_path ++ "/src/video/SDL_blit_A.c",
    sdl_dep_path ++ "/src/video/SDL_blit_N.c",
    sdl_dep_path ++ "/src/video/SDL_blit_auto.c",
    sdl_dep_path ++ "/src/video/SDL_blit_copy.c",
    sdl_dep_path ++ "/src/video/SDL_blit_slow.c",
    sdl_dep_path ++ "/src/video/SDL_bmp.c",
    sdl_dep_path ++ "/src/video/SDL_clipboard.c",
    sdl_dep_path ++ "/src/video/SDL_egl.c",
    sdl_dep_path ++ "/src/video/SDL_fillrect.c",
    sdl_dep_path ++ "/src/video/SDL_pixels.c",
    sdl_dep_path ++ "/src/video/SDL_rect.c",
    // sdl_dep_path ++ "/src/video/SDL_shape.c",
    sdl_dep_path ++ "/src/video/SDL_stretch.c",
    sdl_dep_path ++ "/src/video/SDL_surface.c",
    sdl_dep_path ++ "/src/video/SDL_video.c",
    sdl_dep_path ++ "/src/video/SDL_vulkan_utils.c",
    sdl_dep_path ++ "/src/video/SDL_yuv.c",
    sdl_dep_path ++ "/src/video/yuv2rgb/yuv_rgb_sse.c",
    sdl_dep_path ++ "/src/video/yuv2rgb/yuv_rgb_std.c",
    sdl_dep_path ++ "/src/video/yuv2rgb/yuv_rgb_lsx.c",

    sdl_dep_path ++ "/src/video/dummy/SDL_nullevents.c",
    sdl_dep_path ++ "/src/video/dummy/SDL_nullframebuffer.c",
    sdl_dep_path ++ "/src/video/dummy/SDL_nullvideo.c",

    sdl_dep_path ++ "/src/render/software/SDL_blendfillrect.c",
    sdl_dep_path ++ "/src/render/software/SDL_blendline.c",
    sdl_dep_path ++ "/src/render/software/SDL_blendpoint.c",
    sdl_dep_path ++ "/src/render/software/SDL_drawline.c",
    sdl_dep_path ++ "/src/render/software/SDL_drawpoint.c",
    sdl_dep_path ++ "/src/render/software/SDL_render_sw.c",
    sdl_dep_path ++ "/src/render/software/SDL_rotate.c",
    sdl_dep_path ++ "/src/render/software/SDL_triangle.c",

    sdl_dep_path ++ "/src/audio/dummy/SDL_dummyaudio.c",

    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapi_combined.c",
    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapi_gamecube.c",
    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapi_luna.c",
    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapi_ps3.c",
    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapi_ps4.c",
    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapi_ps5.c",
    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapi_rumble.c",
    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapi_shield.c",
    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapi_stadia.c",
    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapi_steam.c",
    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapi_steamdeck.c",
    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapi_switch.c",
    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapi_wii.c",
    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapi_xbox360.c",
    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapi_xbox360w.c",
    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapi_xboxone.c",
    sdl_dep_path ++ "/src/joystick/hidapi/SDL_hidapijoystick.c",
};

const sdl_windows_src_files = [_][]const u8{
    // sdl_dep_path ++ "/src/main/generic/SDL_sysmain_callbacks.c",
    sdl_dep_path ++ "/src/core/windows/SDL_hid.c",
    sdl_dep_path ++ "/src/core/windows/SDL_immdevice.c",
    sdl_dep_path ++ "/src/core/windows/SDL_windows.c",
    sdl_dep_path ++ "/src/core/windows/SDL_xinput.c",
    sdl_dep_path ++ "/src/filesystem/windows/SDL_sysfilesystem.c",
    // sdl_dep_path ++ "/src/filesystem/windows/SDL_sysfsops.c",
    sdl_dep_path ++ "/src/haptic/windows/SDL_dinputhaptic.c",
    sdl_dep_path ++ "/src/haptic/windows/SDL_windowshaptic.c",
    sdl_dep_path ++ "/src/hidapi/windows/hid.c",
    sdl_dep_path ++ "/src/joystick/windows/SDL_dinputjoystick.c",
    sdl_dep_path ++ "/src/joystick/windows/SDL_rawinputjoystick.c",
    sdl_dep_path ++ "/src/joystick/windows/SDL_windows_gaming_input.c",
    sdl_dep_path ++ "/src/joystick/windows/SDL_windowsjoystick.c",
    sdl_dep_path ++ "/src/joystick/windows/SDL_xinputjoystick.c",

    sdl_dep_path ++ "/src/loadso/windows/SDL_sysloadso.c",
    sdl_dep_path ++ "/src/locale/windows/SDL_syslocale.c",
    // sdl_dep_path ++ "/src/main/windows/SDL_windows_main.c",
    sdl_dep_path ++ "/src/misc/windows/SDL_sysurl.c",
    sdl_dep_path ++ "/src/power/windows/SDL_syspower.c",
    sdl_dep_path ++ "/src/sensor/windows/SDL_windowssensor.c",
    sdl_dep_path ++ "/src/time/windows/SDL_systime.c",
    sdl_dep_path ++ "/src/timer/windows/SDL_systimer.c",
    sdl_dep_path ++ "/src/video/windows/SDL_windowsclipboard.c",
    sdl_dep_path ++ "/src/video/windows/SDL_windowsevents.c",
    sdl_dep_path ++ "/src/video/windows/SDL_windowsframebuffer.c",
    sdl_dep_path ++ "/src/video/windows/SDL_windowskeyboard.c",
    sdl_dep_path ++ "/src/video/windows/SDL_windowsmessagebox.c",
    sdl_dep_path ++ "/src/video/windows/SDL_windowsmodes.c",
    sdl_dep_path ++ "/src/video/windows/SDL_windowsmouse.c",
    sdl_dep_path ++ "/src/video/windows/SDL_windowsopengl.c",
    sdl_dep_path ++ "/src/video/windows/SDL_windowsopengles.c",
    sdl_dep_path ++ "/src/video/windows/SDL_windowsrawinput.c",
    sdl_dep_path ++ "/src/video/windows/SDL_windowsshape.c",
    sdl_dep_path ++ "/src/video/windows/SDL_windowsvideo.c",
    sdl_dep_path ++ "/src/video/windows/SDL_windowsvulkan.c",
    sdl_dep_path ++ "/src/video/windows/SDL_windowswindow.c",

    sdl_dep_path ++ "/src/thread/windows/SDL_syscond_cv.c",
    sdl_dep_path ++ "/src/thread/windows/SDL_sysmutex.c",
    sdl_dep_path ++ "/src/thread/windows/SDL_sysrwlock_srw.c",
    sdl_dep_path ++ "/src/thread/windows/SDL_syssem.c",
    sdl_dep_path ++ "/src/thread/windows/SDL_systhread.c",
    sdl_dep_path ++ "/src/thread/windows/SDL_systls.c",
    sdl_dep_path ++ "/src/thread/generic/SDL_syscond.c",

    sdl_dep_path ++ "/src/render/direct3d/SDL_render_d3d.c",
    sdl_dep_path ++ "/src/render/direct3d/SDL_shaders_d3d.c",
    sdl_dep_path ++ "/src/render/direct3d11/SDL_render_d3d11.c",
    sdl_dep_path ++ "/src/render/direct3d11/SDL_shaders_d3d11.c",
    sdl_dep_path ++ "/src/render/direct3d12/SDL_render_d3d12.c",
    sdl_dep_path ++ "/src/render/direct3d12/SDL_shaders_d3d12.c",

    sdl_dep_path ++ "/src/audio/directsound/SDL_directsound.c",
    sdl_dep_path ++ "/src/audio/wasapi/SDL_wasapi.c",
    sdl_dep_path ++ "/src/audio/wasapi/SDL_wasapi_win32.c",
    // sdl_dep_path ++ "/src/audio/winmm/SDL_winmm.c",
    sdl_dep_path ++ "/src/audio/disk/SDL_diskaudio.c",

    sdl_dep_path ++ "/src/render/opengl/SDL_render_gl.c",
    sdl_dep_path ++ "/src/render/opengl/SDL_shaders_gl.c",
    // sdl_dep_path ++ "/src/render/opengles/SDL_render_gles.c",
    sdl_dep_path ++ "/src/render/opengles2/SDL_render_gles2.c",
    sdl_dep_path ++ "/src/render/opengles2/SDL_shaders_gles2.c",

    sdl_dep_path ++ "/src/render/vulkan/SDL_render_vulkan.c",
    sdl_dep_path ++ "/src/render/vulkan/SDL_shaders_vulkan.c",
};

const ft_srcs = [_][]const u8 {
    ft_dep_path ++ "/src/autofit/autofit.c",
    ft_dep_path ++ "/src/base/ftbase.c",
    ft_dep_path ++ "/src/base/ftbbox.c",
    ft_dep_path ++ "/src/base/ftbdf.c",
    ft_dep_path ++ "/src/base/ftbitmap.c",
    ft_dep_path ++ "/src/base/ftcid.c",
    ft_dep_path ++ "/src/base/ftfstype.c",
    ft_dep_path ++ "/src/base/ftgasp.c",
    ft_dep_path ++ "/src/base/ftglyph.c",
    ft_dep_path ++ "/src/base/ftgxval.c",
    ft_dep_path ++ "/src/base/ftinit.c",
    ft_dep_path ++ "/src/base/ftmm.c",
    ft_dep_path ++ "/src/base/ftotval.c",
    ft_dep_path ++ "/src/base/ftpatent.c",
    ft_dep_path ++ "/src/base/ftpfr.c",
    ft_dep_path ++ "/src/base/ftstroke.c",
    ft_dep_path ++ "/src/base/ftsynth.c",
    ft_dep_path ++ "/src/base/fttype1.c",
    ft_dep_path ++ "/src/base/ftwinfnt.c",
    ft_dep_path ++ "/src/bdf/bdf.c",
    ft_dep_path ++ "/src/bzip2/ftbzip2.c",
    ft_dep_path ++ "/src/cache/ftcache.c",
    ft_dep_path ++ "/src/cff/cff.c",
    ft_dep_path ++ "/src/cid/type1cid.c",
    ft_dep_path ++ "/src/gzip/ftgzip.c",
    ft_dep_path ++ "/src/lzw/ftlzw.c",
    ft_dep_path ++ "/src/pcf/pcf.c",
    ft_dep_path ++ "/src/pfr/pfr.c",
    ft_dep_path ++ "/src/psaux/psaux.c",
    ft_dep_path ++ "/src/pshinter/pshinter.c",
    ft_dep_path ++ "/src/psnames/psnames.c",
    ft_dep_path ++ "/src/raster/raster.c",
    ft_dep_path ++ "/src/sdf/sdf.c",
    ft_dep_path ++ "/src/sfnt/sfnt.c",
    ft_dep_path ++ "/src/smooth/smooth.c",
    ft_dep_path ++ "/src/svg/svg.c",
    ft_dep_path ++ "/src/truetype/truetype.c",
    ft_dep_path ++ "/src/type1/type1.c",
    ft_dep_path ++ "/src/type42/type42.c",
    ft_dep_path ++ "/src/winfonts/winfnt.c",
};

const zlib_srcs = [_][]const u8 {
    zlib_dep_path ++ "/src/adler32.c",
    zlib_dep_path ++ "/src/compress.c",
    zlib_dep_path ++ "/src/crc32.c",
    zlib_dep_path ++ "/src/deflate.c",
    zlib_dep_path ++ "/src/gzclose.c",
    zlib_dep_path ++ "/src/gzlib.c",
    zlib_dep_path ++ "/src/gzread.c",
    zlib_dep_path ++ "/src/gzwrite.c",
    zlib_dep_path ++ "/src/inflate.c",
    zlib_dep_path ++ "/src/infback.c",
    zlib_dep_path ++ "/src/inftrees.c",
    zlib_dep_path ++ "/src/inffast.c",
    zlib_dep_path ++ "/src/trees.c",
    zlib_dep_path ++ "/src/uncompr.c",
    zlib_dep_path ++ "/src/zutil.c",
};

const libpng_headers = [_][]const u8 {
    "png.h",
    "pngconf.h",
    "pngdebug.h",
    "pnginfo.h",
    "pngpriv.h",
    "pngstruct.h",
};

const libpng_srcs = [_][]const u8 {
    libpng_dep_path ++ "/src/png.c",
    libpng_dep_path ++ "/src//png.c",
    libpng_dep_path ++ "/src//pngerror.c",
    libpng_dep_path ++ "/src//pngget.c",
    libpng_dep_path ++ "/src//pngmem.c",
    libpng_dep_path ++ "/src//pngpread.c",
    libpng_dep_path ++ "/src//pngread.c",
    libpng_dep_path ++ "/src//pngrio.c",
    libpng_dep_path ++ "/src//pngrtran.c",
    libpng_dep_path ++ "/src//pngrutil.c",
    libpng_dep_path ++ "/src//pngset.c",
    libpng_dep_path ++ "/src//pngtrans.c",
    libpng_dep_path ++ "/src//pngwio.c",
    libpng_dep_path ++ "/src//pngwrite.c",
    libpng_dep_path ++ "/src//pngwtran.c",
    libpng_dep_path ++ "/src//pngwutil.c",
};

const cglm_srcs = [_][]const u8 {
    cglm_dep_path ++ "/src/euler.c",
    cglm_dep_path ++ "/src/affine.c",
    cglm_dep_path ++ "/src/io.c",
    cglm_dep_path ++ "/src/quat.c",
    cglm_dep_path ++ "/src/cam.c",
    cglm_dep_path ++ "/src/vec2.c",
    cglm_dep_path ++ "/src/vec3.c",
    cglm_dep_path ++ "/src/vec4.c",
    cglm_dep_path ++ "/src/mat2.c",
    cglm_dep_path ++ "/src/mat3.c",
    cglm_dep_path ++ "/src/mat4.c",
    cglm_dep_path ++ "/src/plane.c",
    cglm_dep_path ++ "/src/frustum.c",
    cglm_dep_path ++ "/src/box.c",
    cglm_dep_path ++ "/src/project.c",
    cglm_dep_path ++ "/src/sphere.c",
    cglm_dep_path ++ "/src/ease.c",
    cglm_dep_path ++ "/src/curve.c",
    cglm_dep_path ++ "/src/bezier.c",
    cglm_dep_path ++ "/src/ray.c",
    cglm_dep_path ++ "/src/affine2d.c",
};

const seika_srcs = [_][]const u8 {
    seika_dep_path ++ "/assert.c",
    seika_dep_path ++ "/command_line_args_util.c",
    seika_dep_path ++ "/event.c",
    seika_dep_path ++ "/file_system.c",
    seika_dep_path ++ "/logger.c",
    seika_dep_path ++ "/memory.c",
    seika_dep_path ++ "/platform.c",
    seika_dep_path ++ "/seika.c",
    seika_dep_path ++ "/string.c",
    seika_dep_path ++ "/asset/asset_file_loader.c",
    seika_dep_path ++ "/asset/asset_manager.c",
    seika_dep_path ++ "/audio/audio.c",
    seika_dep_path ++ "/audio/audio_manager.c",
    seika_dep_path ++ "/data_structures/array2d.c",
    seika_dep_path ++ "/data_structures/array_list.c",
    seika_dep_path ++ "/data_structures/array_utils.c",
    seika_dep_path ++ "/data_structures/hash_map.c",
    seika_dep_path ++ "/data_structures/hash_map_string.c",
    seika_dep_path ++ "/data_structures/linked_list.c",
    seika_dep_path ++ "/data_structures/queue.c",
    seika_dep_path ++ "/data_structures/spatial_hash_map.c",
    seika_dep_path ++ "/ecs/component.c",
    seika_dep_path ++ "/ecs/ec_system.c",
    seika_dep_path ++ "/ecs/ecs.c",
    seika_dep_path ++ "/ecs/entity.c",
    seika_dep_path ++ "/input/input.c",
    seika_dep_path ++ "/math/curve_float.c",
    seika_dep_path ++ "/math/math.c",
    seika_dep_path ++ "/networking/network.c",
    seika_dep_path ++ "/networking/network_socket.c",
    seika_dep_path ++ "/rendering/font.c",
    seika_dep_path ++ "/rendering/frame_buffer.c",
    seika_dep_path ++ "/rendering/render_context.c",
    seika_dep_path ++ "/rendering/renderer.c",
    seika_dep_path ++ "/rendering/texture.c",
    seika_dep_path ++ "/rendering/shader/shader.c",
    seika_dep_path ++ "/rendering/shader/shader_cache.c",
    seika_dep_path ++ "/rendering/shader/shader_file_parser.c",
    seika_dep_path ++ "/rendering/shader/shader_instance.c",
    seika_dep_path ++ "/thread/pthread.c",
    seika_dep_path ++ "/thread/thread_pool.c",
};
