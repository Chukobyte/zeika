pub const seika = @cImport({
    @cInclude("seika/seika.h");
    @cInclude("seika/memory.h");
    @cInclude("seika/file_system.h");
    @cInclude("seika/rendering/texture.h");
    @cInclude("seika/rendering/font.h");
    @cInclude("seika/rendering/renderer.h");
    @cInclude("seika/rendering/render_context.h");
    @cInclude("seika/input/input.h");
});
