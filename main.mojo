from gl import *
from glad import *
from glfw import *
from gpu_texture import GPUTexture
from vec import *

from gpu.host import DeviceContext
from gpu import global_idx
from math import ceildiv, cos, sin
from sys.info import size_of
from sys.intrinsics import llvm_intrinsic
from sys.ffi import external_call

alias width = 640
alias height = 480


@always_inline
fn calc_normal[
    df: fn (var Vec3, Float32) -> Float32, eps: Float32 = 0.005
](p: Vec3, time: Float32) -> Vec3:
    return Vec3(
        df(p + Vec3(eps, 0.0, 0.0), time) - df(p - Vec3(eps, 0.0, 0.0), time),
        df(p + Vec3(0.0, eps, 0.0), time) - df(p - Vec3(0.0, eps, 0.0), time),
        df(p + Vec3(0.0, 0.0, eps), time) - df(p - Vec3(0.0, 0.0, eps), time),
    ).normalize()


@always_inline
fn rot2d(p: Vec2, a: Float32) -> Vec2:
    var c = cos(a)
    var s = sin(a)
    return {p.x * c - p.y * s, p.x * s + p.y * c}


@always_inline
fn map(var p: Vec3, time: Float32) -> Float32:
    var q = p
    var p2 = rot2d({p.x, p.y}, q.z * 0.1 + time * 0.1)
    p = Vec3(p2.x, p2.y, p.z)
    p = (p % 2.0) - 1.0
    return p.length() - 0.4


@always_inline
fn trace[
    df: fn (var Vec3, Float32) -> Float32,
    far: Float32 = 20.0,
    eps: Float32 = 0.001,
](ro: Vec3, rd: Vec3, time: Float32) -> Float32:
    var t = Float32(0)
    for _ in range(250):
        var p = ro + rd * t
        var m = map(p, time)
        t += m * 0.75
        if t > far or m < eps:
            break
    return t


@always_inline
fn calc_cam(uv: Vec2, ro: Vec3, rd: Vec3, fov: Float32) -> Vec3:
    var cu = Vec3(0.0, 1.0, 0.0).normalize()
    var z = (cu - ro).normalize()
    var x = cu.cross(z).normalize()
    var y = z.cross(x)
    return (z + fov * uv.x * x + fov * uv.y * y).normalize()


@always_inline
fn main_image(uv: Vec2, time: Float32) -> Vec3:
    var q = uv * 2.0 - 1.0
    (UnsafePointer(to=q).bitcast[Float32]())[] *= Float32(width) / Float32(
        height
    )
    var ro = Vec3(0.0, 0.0, time + 5.0)
    var cv = ro + Vec3(0.0, 0.0, 4.0)
    var rd = calc_cam(q, ro, cv, 0.4)
    var t = trace[map](ro, rd, time)
    var p = ro + rd * t
    var n = calc_normal[map](p, time)
    if t > 20.0:
        return Vec3(0.0, 0.0, 0.0)
    alias lp = Vec3(0.0, 0.5, 0.0)
    var ld = (lp - p).normalize()
    var diff = n.dot(ld) * 0.5 + 0.5
    diff *= diff
    var color = Vec3(diff, diff, diff)

    return color
    # return {uv.x, uv.y, sin(time) * 0.5 + 0.5}


fn kernel(ptr: UnsafePointer[UInt32], time: Float32):
    var idx = global_idx.x
    if idx > width * height:
        return

    var x = idx % width
    var y = idx // width

    var uv = Vec2(Float32(x) / width, Float32(y) / height)
    var col = main_image(uv, time)

    var r = UInt8(col.x * 255.0)
    var g = UInt8(col.y * 255.0)
    var b = UInt8(col.z * 255.0)
    var a = UInt8(255)
    ptr.bitcast[SIMD[DType.uint8, 4]]()[idx] = {b, g, r, a}


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


struct App:
    var window: UnsafePointer[GLFWwindow]
    var shader_program: UInt32
    var vao: UInt32
    var vbo: UInt32
    var animation_time: Float32

    fn __init__(out self) raises:
        self.shader_program = 0
        self.vao = 0
        self.vbo = 0
        self.animation_time = 0.0

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

        var fragment_shader_source = String(
            """
        #version 330 core
        out vec4 FragColor;
        in vec2 TexCoord;
        uniform sampler2DRect ourTexture;
        void main() {
            vec2 rectCoord = TexCoord * vec2(""",
            Float32(width),
            ",",
            Float32(height),
            """);
            FragColor = texture(ourTexture, rectCoord);
        }
        """,
        )

        var vertices: InlineArray[Float32, 20] = [
            # fmt: off
            # positions       texture coords
             1.0,  1.0, 0.0,  1.0, 1.0, # top right
             1.0, -1.0, 0.0,  1.0, 0.0, # bottom right
            -1.0, -1.0, 0.0,  0.0, 0.0, # bottom left
            -1.0,  1.0, 0.0,  0.0, 1.0,
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

        glfw_window_hint(GLFW_OPENGL_FORWARD_COMPAT, 1)
        glfw_window_hint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE)
        glfw_window_hint(GLFW_CONTEXT_VERSION_MAJOR, 3)
        glfw_window_hint(GLFW_CONTEXT_VERSION_MINOR, 3)

        var title = "Hello GLFW"
        self.window = glfw_create_window(width, height, title)

        glfw_make_context_current(self.window)

        _ = glad_load_gl_loader(glfw_get_proc_address)

        var vertex_shader = compile_shader(
            GL_VERTEX_SHADER, vertex_shader_source
        )
        var fragment_shader = compile_shader(
            GL_FRAGMENT_SHADER, fragment_shader_source
        )

        self.shader_program = gl_create_program()
        gl_attach_shader(self.shader_program, vertex_shader)
        gl_attach_shader(self.shader_program, fragment_shader)
        gl_link_program(self.shader_program)

        var success = Int32(0)
        gl_get_programiv(
            self.shader_program, GL_LINK_STATUS, UnsafePointer(to=success)
        )
        if not success:
            var info_log = InlineArray[Int8, 512](uninitialized=True)
            gl_get_program_info_log(
                self.shader_program, 512, {}, info_log.unsafe_ptr()
            )
            raise Error(
                String(
                    "Shader program linking failed: ",
                    StringSlice(unsafe_from_utf8_ptr=info_log.unsafe_ptr()),
                )
            )

        gl_delete_shader(vertex_shader)
        gl_delete_shader(fragment_shader)

        gl_gen_vertex_arrays(1, UnsafePointer(to=self.vao))
        gl_gen_buffers(1, UnsafePointer(to=self.vbo))

        gl_bind_vertex_array(self.vao)
        gl_bind_buffer(GL_ARRAY_BUFFER, self.vbo)
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

        # Create offset as an integer and cast to pointer
        var offset = 3 * size_of[Float32]()
        var ptr = UnsafePointer(to=offset).bitcast[OpaquePointer]()[]
        gl_vertex_attrib_pointer(
            1, 2, GL_FLOAT, GL_FALSE, 5 * size_of[Float32](), ptr
        )
        gl_enable_vertex_attrib_array(1)

        gl_use_program(self.shader_program)

        var tex_string = "ourTexture"
        var texture_uniform = gl_get_uniform_location(
            self.shader_program, tex_string.unsafe_cstr_ptr()
        )
        gl_uniform1i(texture_uniform, 0)

    fn __del__(deinit self):
        gl_delete_vertex_arrays(1, UnsafePointer(to=self.vao))
        gl_delete_buffers(1, UnsafePointer(to=self.vbo))
        gl_delete_program(self.shader_program)
        glfw_destroy_window(self.window)

    fn run(mut self) raises:
        with DeviceContext() as ctx:
            var tex = GPUTexture(width=width, height=height, ctx=ctx)

            var buf = ctx.enqueue_create_buffer[DType.uint32](
                tex.width * tex.height
            )

            while not glfw_window_should_close(self.window):
                glfw_poll_events()

                if glfw_get_key(self.window, GLFW_KEY_ESCAPE) == GLFW_PRESS:
                    glfw_set_window_should_close(self.window, GLFW_TRUE)

                ctx.enqueue_function_checked[kernel, kernel](
                    buf,
                    self.animation_time,
                    grid_dim=ceildiv(width * height, 256),
                    block_dim=256,
                )

                tex.copy_from(buf, ctx)
                gl_clear(GL_COLOR_BUFFER_BIT)

                gl_use_program(self.shader_program)
                gl_active_texture(GL_TEXTURE0)
                gl_bind_texture(GL_TEXTURE_RECTANGLE, tex.gl_texture)
                gl_bind_vertex_array(self.vao)
                gl_draw_elements(
                    GL_TRIANGLES,
                    6,
                    GL_UNSIGNED_INT,
                    {},
                )

                self.animation_time += 0.01
                glfw_swap_buffers(self.window)


fn main() raises:
    glfw_init()
    var app = App()
    app.run()
    glfw_terminate()
