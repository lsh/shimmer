from sys.ffi import external_call

alias NSUInteger = UInt64


@fieldwise_init
@register_passable("trivial")
struct MTLOrigin(Copyable, Movable):
    var x: NSUInteger
    var y: NSUInteger
    var z: NSUInteger


@fieldwise_init
@register_passable("trivial")
struct MTLSize(Copyable, Movable):
    var width: NSUInteger
    var height: NSUInteger
    var depth: NSUInteger


@fieldwise_init
@register_passable("trivial")
struct MTLRegion(Copyable, Movable):
    var origin: MTLOrigin
    var size: MTLSize

    fn __init__(
        out self,
        x: NSUInteger,
        y: NSUInteger,
        width: NSUInteger,
        height: NSUInteger,
    ):
        self.origin = MTLOrigin(x, y, 0)
        self.size = MTLSize(width, height, 1)


fn sel_register_name(mut name: String) -> OpaquePointer:
    return external_call[
        "sel_registerName", OpaquePointer, UnsafePointer[Int8]
    ](name.unsafe_cstr_ptr())


fn objc_msg_send(
    obj: OpaquePointer,
    sel: OpaquePointer,
    arg0: MTLRegion,
    arg1: NSUInteger,
    arg2: OpaquePointer,
    arg3: NSUInteger,
) -> OpaquePointer:
    return external_call[
        "objc_msgSend",
        OpaquePointer,
        OpaquePointer,
        OpaquePointer,
        MTLRegion,
        NSUInteger,
        OpaquePointer,
        NSUInteger,
    ](obj, sel, arg0, arg1, arg2, arg3)


fn cv_pixel_buffer_write_bytes(
    pixel_buffer: OpaquePointer,
    pixel_bytes: UnsafePointer[UInt8],
    bytes_per_row: NSUInteger,
    width: NSUInteger,
    height: NSUInteger,
):
    external_call[
        "CVPixelBuffer_writeBytes",
        NoneType,
        OpaquePointer,
        UnsafePointer[UInt8],
        NSUInteger,
        NSUInteger,
        NSUInteger,
    ](pixel_buffer, pixel_bytes, bytes_per_row, width, height)
