from sys.ffi import external_call

alias GL_COLOR_BUFFER_BIT = 0x00004000
alias GL_VERTEX_SHADER = 0x8B31
alias GL_FRAGMENT_SHADER = 0x8B30
alias GL_LINK_STATUS = 0x8B82
alias GL_PIXEL_UNPACK_BUFFER = 0x88EC
alias GL_ARRAY_BUFFER = 0x8892
alias GL_STATIC_DRAW = 0x88E4
alias GL_FLOAT = 0x1406
alias GL_FALSE = 0
alias GL_TRIANGLES = 0x0004
alias GL_TEXTURE_2D = 0x0DE1
alias GL_TEXTURE_RECTANGLE = 0x84F5
alias GL_LINEAR = 0x2601
alias GL_CLAMP_TO_EDGE = 0x812F
alias GL_RGBA8 = 0x8058
alias GL_RGBA = 0x1908
alias GL_BGRA = 0x80E1
alias GL_UNSIGNED_BYTE = 0x1401
alias GL_TEXTURE_MIN_FILTER = 0x2801
alias GL_TEXTURE_MAG_FILTER = 0x2800
alias GL_TEXTURE_WRAP_S = 0x2802
alias GL_TEXTURE_WRAP_T = 0x2803
alias GL_DYNAMIC_DRAW = 0x88E8
alias GL_UNSIGNED_INT = 0x1405
alias GL_ELEMENT_ARRAY_BUFFER = 0x8893
alias GL_TEXTURE0 = 0x84C0
alias GL_WRITE_ONLY = 0x88B9


fn gl_clear(mask: Int32):
    _ = external_call["glClear", NoneType, Int32](mask)


fn gl_create_shader(shader_type: UInt32) -> UInt32:
    return external_call["glCreateShader", UInt32, UInt32](shader_type)


fn gl_shader_source(
    shader: UInt32,
    count: Int32,
    string: UnsafePointer[UnsafePointer[Int8]],
    length: UnsafePointer[Int32, address_space = AddressSpace.GENERIC, **_],
):
    _ = external_call[
        "glShaderSource",
        NoneType,
        UInt32,
        Int32,
        UnsafePointer[UnsafePointer[Int8]],
        UnsafePointer[Int32],
    ](shader, count, string, length)


fn gl_compile_shader(shader: UInt32):
    _ = external_call["glCompileShader", NoneType, UInt32](shader)


alias GL_COMPILE_STATUS = 0x8B81


fn gl_get_shaderiv(
    shader: UInt32,
    pname: UInt32,
    params: UnsafePointer[Int32, address_space = AddressSpace.GENERIC, **_],
):
    _ = external_call[
        "glGetShaderiv",
        NoneType,
        UInt32,
        UInt32,
        UnsafePointer[Int32],
    ](shader, pname, params)


fn gl_get_shader_info_log(
    shader: UInt32,
    buf_size: Int32,
    length: UnsafePointer[Int32, address_space = AddressSpace.GENERIC, **_],
    info_log: UnsafePointer[Int8, address_space = AddressSpace.GENERIC, **_],
):
    _ = external_call[
        "glGetShaderInfoLog",
        NoneType,
        UInt32,
        Int32,
        UnsafePointer[Int32],
        UnsafePointer[Int8],
    ](shader, buf_size, length, info_log)


fn gl_create_program() -> UInt32:
    return external_call["glCreateProgram", UInt32]()


fn gl_use_program(program: UInt32):
    _ = external_call["glUseProgram", NoneType, UInt32](program)


fn gl_attach_shader(program: UInt32, shader: UInt32):
    _ = external_call["glAttachShader", NoneType, UInt32, UInt32](
        program, shader
    )


fn gl_link_program(program: UInt32):
    _ = external_call["glLinkProgram", NoneType, UInt32](program)


fn gl_delete_shader(shader: UInt32):
    _ = external_call["glDeleteShader", NoneType, UInt32](shader)


fn gl_bind_vertex_array(array: UInt32):
    _ = external_call["glBindVertexArray", NoneType, UInt32](array)


fn gl_gen_vertex_arrays(
    n: Int32,
    arrays: UnsafePointer[UInt32, address_space = AddressSpace.GENERIC, **_],
):
    _ = external_call[
        "glGenVertexArrays", NoneType, Int32, UnsafePointer[UInt32]
    ](n, arrays)


fn gl_gen_buffers(
    n: Int32,
    buffers: UnsafePointer[UInt32, address_space = AddressSpace.GENERIC, **_],
):
    _ = external_call["glGenBuffers", NoneType, Int32, UnsafePointer[UInt32]](
        n, buffers
    )


fn gl_bind_buffer(target: Int32, buffer: UInt32):
    _ = external_call["glBindBuffer", NoneType, Int32, UInt32](target, buffer)


fn gl_buffer_data(
    target: Int32, size: Int64, data: OpaquePointer, usage: Int32
):
    _ = external_call[
        "glBufferData", NoneType, Int32, Int64, OpaquePointer, Int32
    ](target, size, data, usage)


fn gl_vertex_attrib_pointer(
    index: UInt32,
    size: Int32,
    type: Int32,
    normalized: Bool,
    stride: Int32,
    pointer: OpaquePointer,
):
    _ = external_call[
        "glVertexAttribPointer",
        NoneType,
        UInt32,
        Int32,
        Int32,
        Bool,
        Int32,
        OpaquePointer,
    ](index, size, type, normalized, stride, pointer)


fn gl_enable_vertex_attrib_array(index: UInt32):
    _ = external_call["glEnableVertexAttribArray", NoneType, UInt32](index)


fn gl_draw_arrays(mode: Int32, first: Int32, count: Int32):
    _ = external_call["glDrawArrays", NoneType, Int32, Int32, Int32](
        mode, first, count
    )


fn gl_draw_elements(
    mode: Int32, count: Int32, type: Int32, indices: OpaquePointer
):
    _ = external_call[
        "glDrawElements", NoneType, Int32, Int32, Int32, OpaquePointer
    ](mode, count, type, indices)


fn gl_get_programiv(
    program: UInt32,
    pname: Int32,
    params: UnsafePointer[Int32, address_space = AddressSpace.GENERIC, **_],
):
    _ = external_call[
        "glGetProgramiv",
        NoneType,
        UInt32,
        Int32,
        UnsafePointer[Int32],
    ](program, pname, params)


fn gl_get_program_info_log(
    program: UInt32,
    buf_size: Int32,
    length: UnsafePointer[Int32, address_space = AddressSpace.GENERIC, **_],
    info_log: UnsafePointer[Int8, address_space = AddressSpace.GENERIC, **_],
):
    _ = external_call[
        "glGetProgramInfoLog",
        NoneType,
        UInt32,
        Int32,
        UnsafePointer[Int32],
        UnsafePointer[Int8],
    ](program, buf_size, length, info_log)


fn gl_gen_textures(
    n: Int32,
    textures: UnsafePointer[UInt32, address_space = AddressSpace.GENERIC, **_],
):
    _ = external_call["glGenTextures", NoneType, Int32, UnsafePointer[UInt32]](
        n, textures
    )


fn gl_bind_texture(target: UInt32, texture: UInt32):
    _ = external_call["glBindTexture", NoneType, UInt32, UInt32](
        target, texture
    )


fn gl_tex_parameteri(target: UInt32, pname: Int32, param: Int32):
    _ = external_call["glTexParameteri", NoneType, UInt32, Int32, Int32](
        target, pname, param
    )


fn gl_tex_image_2d(
    target: UInt32,
    level: Int32,
    internal_format: Int32,
    width: Int32,
    height: Int32,
    border: Int32,
    format: Int32,
    type: Int32,
    data: OpaquePointer,
):
    _ = external_call[
        "glTexImage2D",
        NoneType,
        UInt32,
        Int32,
        Int32,
        Int32,
        Int32,
        Int32,
        Int32,
        Int32,
        OpaquePointer,
    ](
        target,
        level,
        internal_format,
        width,
        height,
        border,
        format,
        type,
        data,
    )


fn gl_delete_program(program: UInt32):
    _ = external_call["glDeleteProgram", NoneType, UInt32](program)


fn gl_delete_buffers(
    n: Int32,
    buffers: UnsafePointer[UInt32, address_space = AddressSpace.GENERIC, **_],
):
    _ = external_call[
        "glDeleteBuffers", NoneType, Int32, UnsafePointer[UInt32]
    ](n, buffers)


fn gl_delete_textures(
    n: Int32,
    textures: UnsafePointer[UInt32, address_space = AddressSpace.GENERIC, **_],
):
    _ = external_call[
        "glDeleteTextures", NoneType, Int32, UnsafePointer[UInt32]
    ](n, textures)


fn gl_delete_vertex_arrays(
    n: Int32,
    arrays: UnsafePointer[UInt32, address_space = AddressSpace.GENERIC, **_],
):
    _ = external_call[
        "glDeleteVertexArrays", NoneType, Int32, UnsafePointer[UInt32]
    ](n, arrays)


fn gl_active_texture(texture: UInt32):
    _ = external_call["glActiveTexture", NoneType, UInt32](texture)


fn gl_get_uniform_location(program: UInt32, name: UnsafePointer[Int8]) -> Int32:
    return external_call[
        "glGetUniformLocation", Int32, UInt32, UnsafePointer[Int8]
    ](program, name)


fn gl_uniform1i(location: Int32, v0: Int32):
    _ = external_call["glUniform1i", NoneType, Int32, Int32](location, v0)


fn gl_map_buffer(target: Int32, access: Int32) -> OpaquePointer:
    return external_call["glMapBuffer", OpaquePointer, Int32, Int32](
        target, access
    )


fn gl_unmap_buffer(target: Int32) -> Bool:
    return external_call["glUnmapBuffer", Bool, Int32](target)


fn gl_tex_sub_image_2d(
    target: UInt32,
    level: Int32,
    xoffset: Int32,
    yoffset: Int32,
    width: Int32,
    height: Int32,
    format: Int32,
    type: Int32,
    pixels: OpaquePointer,
):
    _ = external_call[
        "glTexSubImage2D",
        NoneType,
        UInt32,
        Int32,
        Int32,
        Int32,
        Int32,
        Int32,
        Int32,
        Int32,
        OpaquePointer,
    ](target, level, xoffset, yoffset, width, height, format, type, pixels)
