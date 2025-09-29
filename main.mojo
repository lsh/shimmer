from gl import *

from glfw import *
from glad import *
from objc import *
from gpu_texture import GPUTexture

from gpu.host import DeviceContext
from gpu import global_idx
from math import ceildiv
from sys.info import size_of
from sys.intrinsics import llvm_intrinsic
from sys.ffi import external_call


fn kernel(ptr: UnsafePointer[UInt32], time: Float32):
    var idx = global_idx.x
    if idx > 640 * 480:
        return

    var x = idx % 640
    var y = idx // 640

    var u = Float32(x) / 640.0
    var v = Float32(y) / 480.0

    var r = UInt32(u * 255.0)
    var g = UInt32(v * 255.0)
    var b = UInt32(1)
    var a = UInt32(255)

    ptr[idx] = (a << 24) | (r << 16) | (g << 8) | b


fn compile_shader(type: UInt32, mut source: String) raises -> UInt32:
    var shader = gl_create_shader(type)
    var ptr = source.unsafe_cstr_ptr().origin_cast[True, MutableAnyOrigin]()
    var length = Int32(len(source))
    gl_shader_source(shader, 1, UnsafePointer(to=ptr), UnsafePointer(to=length))
    gl_compile_shader(shader)

    var success = Int32(0)
    gl_get_shaderiv(shader, GL_COMPILE_STATUS, UnsafePointer(to=success))

    if not success:
        var info_log = InlineArray[Int8, 512](uninitialized=True)
        var length = InlineArray[Int32, 1](0)
        gl_get_shader_info_log(
            shader, 512, length.unsafe_ptr(), info_log.unsafe_ptr()
        )
        raise Error("Shader compilation failed")

    return shader


fn init_opengl(
    mut vertex_shader_source: String,
    mut fragment_shader_source: String,
    mut shader_program: UInt32,
    mut vao: UInt32,
    mut vbo: UInt32,
    vertices: InlineArray[Float32, 20],
    indices: InlineArray[Int32, 6],
    texture: GPUTexture,
) raises:
    var vertex_shader = compile_shader(GL_VERTEX_SHADER, vertex_shader_source)
    var fragment_shader = compile_shader(
        GL_FRAGMENT_SHADER, fragment_shader_source
    )

    shader_program = gl_create_program()
    gl_attach_shader(shader_program, vertex_shader)
    gl_attach_shader(shader_program, fragment_shader)
    gl_link_program(shader_program)

    var success = Int32(0)
    gl_get_programiv(shader_program, GL_LINK_STATUS, UnsafePointer(to=success))
    if not success:
        var info_log = InlineArray[Int8, 512](uninitialized=True)
        gl_get_program_info_log(shader_program, 512, {}, info_log.unsafe_ptr())
        raise Error(
            String(
                "Shader program linking failed: ",
                StringSlice(unsafe_from_utf8_ptr=info_log.unsafe_ptr()),
            )
        )

    gl_delete_shader(vertex_shader)
    gl_delete_shader(fragment_shader)

    gl_gen_vertex_arrays(1, UnsafePointer(to=vao))
    gl_gen_buffers(1, UnsafePointer(to=vbo))

    gl_bind_vertex_array(vao)
    gl_bind_buffer(GL_ARRAY_BUFFER, vbo)
    gl_buffer_data(
        GL_ARRAY_BUFFER,
        size_of[__type_of(vertices)](),
        vertices.unsafe_ptr().bitcast[NoneType](),
        GL_STATIC_DRAW,
    )

    var ebo = UInt32(0)
    gl_gen_buffers(1, UnsafePointer(to=ebo))
    gl_bind_buffer(GL_ELEMENT_ARRAY_BUFFER, ebo)
    gl_buffer_data(
        GL_ELEMENT_ARRAY_BUFFER,
        size_of[__type_of(indices)](),
        indices.unsafe_ptr().bitcast[NoneType](),
        GL_STATIC_DRAW,
    )

    gl_vertex_attrib_pointer(
        0, 3, GL_FLOAT, GL_FALSE, 5 * size_of[Float32](), {}
    )
    gl_enable_vertex_attrib_array(0)

    var ptr = OpaquePointer() + 3 * size_of[Float32]()
    gl_vertex_attrib_pointer(
        1, 2, GL_FLOAT, GL_FALSE, 5 * size_of[Float32](), ptr
    )
    gl_enable_vertex_attrib_array(1)

    # Set texture uniform
    gl_use_program(shader_program)

    var tex_string = "ourTexture"
    var texture_uniform = gl_get_uniform_location(
        shader_program, tex_string.unsafe_cstr_ptr()
    )
    gl_uniform1i(texture_uniform, 0)


fn render(
    shader_program: UInt32,
    texture_id: UInt32,
    vao: UInt32,
):
    gl_clear(GL_COLOR_BUFFER_BIT)

    gl_use_program(shader_program)
    gl_active_texture(GL_TEXTURE0)
    gl_bind_texture(GL_TEXTURE_RECTANGLE, texture_id)
    gl_bind_vertex_array(vao)
    gl_draw_elements(
        GL_TRIANGLES,
        6,
        GL_UNSIGNED_INT,
        {},
    )


fn cleanup(
    mut vao: UInt32,
    mut vbo: UInt32,
    mut texture_id: UInt32,
    mut shader_program: UInt32,
):
    gl_delete_vertex_arrays(1, UnsafePointer(to=vao))
    gl_delete_buffers(1, UnsafePointer(to=vbo))
    gl_delete_textures(1, UnsafePointer(to=texture_id))
    gl_delete_program(shader_program)


fn error_callback(error: Int32, description: UnsafePointer[Int8]):
    var desc_str = StaticString(unsafe_from_utf8_ptr=description)
    print("GLFW Error (", error, "): ", desc_str)


fn main() raises:
    var texture_id = UInt32(0)
    var shader_program = UInt32(0)
    var vao = UInt32(0)
    var vbo = UInt32(0)
    var animation_time = Float32(0)

    var vertex_shader_source = """
    #version 330 core
    layout (location = 0) in vec3 aPos;
    layout (location = 1) in vec2 aTexCoord;
    out vec2 TexCoord;
    void main() {
        gl_Position = vec4(aPos, 1.0);
        TexCoord = aTexCoord;
    }
    """

    var fragment_shader_source = """
    #version 330 core
    out vec4 FragColor;
    in vec2 TexCoord;
    uniform sampler2DRect ourTexture;
    void main() {
        vec2 rectCoord = TexCoord * vec2(640.0, 480.0);
        FragColor = texture(ourTexture, rectCoord);
    }
    """

    var vertices: InlineArray[Float32, 20] = [
        # fmt: off
        # positions       texture coords
         1.0,  1.0, 0.0,  1.0, 1.0, # top right
         1.0, -1.0, 0.0,  1.0, 0.0, # bottom right
        -1.0, -1.0, 0.0,  0.0, 0.0, # bottom left
        -1.0,  1.0, 0.0,  0.0, 1.0
        # top left
        # fmt: on
    ]

    var indices: InlineArray[Int32, 6] = [
        # fmt: off
        0, 1, 2, # first triangle
        2, 3, 0
        # second triangle
        # fmt: on
    ]

    glfw_set_error_callback(error_callback)
    glfw_init()
    glfw_window_hint(GLFW_OPENGL_FORWARD_COMPAT, 1)
    glfw_window_hint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE)
    glfw_window_hint(GLFW_CONTEXT_VERSION_MAJOR, 3)
    glfw_window_hint(GLFW_CONTEXT_VERSION_MINOR, 3)

    var title = "Hello GLFW"
    var window = glfw_create_window(640, 480, title)

    glfw_make_context_current(window)

    _ = glad_load_gl_loader(glfw_get_proc_address)

    with DeviceContext() as ctx:
        var tex = GPUTexture(width=640, height=480, window=window, ctx=ctx)
        init_opengl(
            vertex_shader_source,
            fragment_shader_source,
            shader_program,
            vao,
            vbo,
            vertices,
            indices,
            tex,
        )

        var buf = ctx.enqueue_create_buffer[DType.uint32](
            tex.width * tex.height
        )

        with buf.map_to_host() as mapped:
            for i in range(0, len(buf)):
                mapped[i] = UInt32(i % 256)

        while not glfw_window_should_close(window):
            glfw_poll_events()

            if glfw_get_key(window, GLFW_KEY_ESCAPE) == GLFW_PRESS:
                glfw_set_window_should_close(window, GLFW_TRUE)

            ctx.enqueue_function_checked[kernel, kernel](
                buf,
                animation_time,
                grid_dim=ceildiv(640 * 480, 256),
                block_dim=256,
            )

            tex.copy_from(buf, ctx)
            render(shader_program, tex.gl_texture, vao)

            animation_time += 0.01
            glfw_swap_buffers(window)

    glfw_destroy_window(window)

    glfw_terminate()
