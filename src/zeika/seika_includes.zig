pub const seika = @cImport({
    @cInclude("seika/seika.h");
    @cInclude("seika/rendering/texture.h");
    @cInclude("seika/rendering/renderer.h");
    @cInclude("seika/input/input.h");
});