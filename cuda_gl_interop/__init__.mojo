from sys.ffi import external_call

alias cudaGraphicsMapFlagsWriteDiscard = 2


struct cudaGraphicsResource:
    ...


struct CUstream_st:
    ...


fn cuda_graphics_gl_register_buffer(
    resource: UnsafePointer[UnsafePointer[cudaGraphicsResource]],
    buffer: UInt32,
    flags: UInt32,
) -> Int32:
    return external_call[
        "cudaGraphicsGLRegisterBuffer",
        Int32,
        UnsafePointer[UnsafePointer[cudaGraphicsResource]],
        UInt32,
        UInt32,
    ](resource, buffer, flags)


fn cuda_graphics_unregister_resource(
    resource: UnsafePointer[cudaGraphicsResource],
):
    external_call[
        "cudaGraphicsUnregisterResource",
        NoneType,
        UnsafePointer[cudaGraphicsResource],
    ](resource)


fn cuda_graphics_map_resources(
    count: Int32,
    resources: UnsafePointer[UnsafePointer[cudaGraphicsResource]],
    stream: UnsafePointer[CUstream_st] = {},
) -> Int32:
    return external_call[
        "cudaGraphicsMapResources",
        Int32,
        Int32,
        UnsafePointer[UnsafePointer[cudaGraphicsResource]],
        UnsafePointer[CUstream_st],
    ](count, resources, stream)


fn cuda_graphics_unmap_resources(
    count: Int32,
    resources: UnsafePointer[UnsafePointer[cudaGraphicsResource]],
    stream: UnsafePointer[CUstream_st] = {},
) -> Int32:
    return external_call[
        "cudaGraphicsUnmapResources",
        Int32,
        Int32,
        UnsafePointer[UnsafePointer[cudaGraphicsResource]],
        UnsafePointer[CUstream_st],
    ](count, resources, stream)


fn cuda_graphics_resource_get_mapped_pointer(
    devPtr: UnsafePointer[OpaquePointer],
    size: UnsafePointer[UInt64],
    resource: UnsafePointer[cudaGraphicsResource],
) -> Int32:
    return external_call[
        "cudaGraphicsResourceGetMappedPointer",
        Int32,
        UnsafePointer[OpaquePointer],
        UnsafePointer[UInt64],
        UnsafePointer[cudaGraphicsResource],
    ](devPtr, size, resource)


fn cuda_gl_set_gl_device(device: UInt32) -> Int32:
    return external_call["cudaGLSetGLDevice", Int32, UInt32](device)


fn cuda_set_device(device: UInt32):
    external_call["cudaSetDevice", NoneType, UInt32](device)


fn cuda_get_error_string(error: Int32) -> StaticString:
    return StaticString(
        unsafe_from_utf8_ptr=external_call[
            "cudaGetErrorString", UnsafePointer[Int8], Int32
        ](error)
    )
