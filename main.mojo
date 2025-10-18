from gl import *
from glad import *
from glfw import *
from gpu_texture import GPUTexture
from kissfft import KissFFTState
from portaudio import *
from shader_util import Uniforms
from vec import *

from gpu.host import DeviceContext, DeviceBuffer
from gpu import global_idx
from os.fstat import stat
from sys.info import size_of
from sys.intrinsics import llvm_intrinsic
from sys.ffi import DLHandle, external_call
from time import sleep, perf_counter
from complex import ComplexScalar
from math import sqrt


struct AudioAnalyzer:
    """Captures microphone input and analyzes frequency content."""

    var stream: UnsafePointer[PaStream]
    var fft_state: KissFFTState[DType.float32]
    var buffer: List[Float32]
    var fft_input: List[ComplexScalar[DType.float32]]
    var fft_output: List[ComplexScalar[DType.float32]]
    var sample_rate: Float64
    var fft_size: Int
    var low_freq: Float32
    var mid_freq: Float32
    var high_freq: Float32

    fn __init__(
        out self, sample_rate: Float64 = 44100.0, fft_size: Int = 1024
    ) raises:
        """Initialize audio capture and FFT."""
        self.sample_rate = sample_rate
        self.fft_size = fft_size
        self.low_freq = 0.0
        self.mid_freq = 0.0
        self.high_freq = 0.0

        # Initialize PortAudio
        var err = Pa_Initialize()
        if err != paNoError:
            raise Error("Failed to initialize PortAudio")

        # Create buffers
        self.buffer = List[Float32](capacity=fft_size)
        self.buffer.resize(fft_size, 0.0)

        self.fft_input = List[ComplexScalar[DType.float32]](capacity=fft_size)
        self.fft_input.resize(fft_size, ComplexScalar[DType.float32](0.0, 0.0))

        self.fft_output = List[ComplexScalar[DType.float32]](capacity=fft_size)
        self.fft_output.resize(fft_size, ComplexScalar[DType.float32](0.0, 0.0))

        # Initialize FFT
        self.fft_state = KissFFTState[DType.float32](fft_size, inverse=False)

        # Open input stream - PortAudio will allocate the stream
        var stream_ptr = InlineArray[UnsafePointer[PaStream], 1](
            uninitialized=True
        )

        err = Pa_OpenDefaultStream(
            stream_ptr.unsafe_ptr(),
            1,  # input channels
            0,  # output channels
            paFloat32,
            sample_rate,
            UInt(fft_size),
            UnsafePointer[NoneType](),  # no callback
            UnsafePointer[NoneType](),  # no user data
        )

        if err != paNoError:
            raise Error("Failed to open audio stream")

        # PortAudio has allocated the stream, we just store the pointer
        self.stream = stream_ptr[0]

        # Start the stream
        err = Pa_StartStream(self.stream)
        if err != paNoError:
            raise Error("Failed to start audio stream")

    fn __del__(deinit self):
        """Clean up audio resources."""
        _ = Pa_StopStream(self.stream)
        _ = Pa_CloseStream(self.stream)
        _ = Pa_Terminate()

    fn update(mut self) raises:
        """Capture audio and update frequency bands."""
        # Read audio samples
        var err = Pa_ReadStream(
            self.stream,
            self.buffer.unsafe_ptr().bitcast[NoneType](),
            UInt(self.fft_size),
        )

        if err != paNoError and err != paInputOverflowed:
            # Input overflow is acceptable, other errors are not
            return

        # Convert to complex for FFT
        for i in range(self.fft_size):
            self.fft_input[i] = ComplexScalar[DType.float32](
                self.buffer[i], 0.0
            )

        # Perform FFT
        self.fft_state.transform(Span(self.fft_input), Span(self.fft_output), 1)

        # Calculate frequency band energies
        # Low: 20-250 Hz, Mid: 250-2000 Hz, High: 2000-20000 Hz
        var bin_freq = self.sample_rate / Float64(self.fft_size)
        var low_start = Int(20.0 / bin_freq)
        var low_end = Int(250.0 / bin_freq)
        var mid_end = Int(2000.0 / bin_freq)
        var high_end = Int(20000.0 / bin_freq)

        if high_end > self.fft_size // 2:
            high_end = self.fft_size // 2

        var low_energy = Float32(0.0)
        var mid_energy = Float32(0.0)
        var high_energy = Float32(0.0)

        # Sum magnitudes in each band
        for i in range(low_start, low_end):
            var mag = sqrt(
                self.fft_output[i].re * self.fft_output[i].re
                + self.fft_output[i].im * self.fft_output[i].im
            )
            low_energy += mag

        for i in range(low_end, mid_end):
            var mag = sqrt(
                self.fft_output[i].re * self.fft_output[i].re
                + self.fft_output[i].im * self.fft_output[i].im
            )
            mid_energy += mag

        for i in range(mid_end, high_end):
            var mag = sqrt(
                self.fft_output[i].re * self.fft_output[i].re
                + self.fft_output[i].im * self.fft_output[i].im
            )
            high_energy += mag

        # Normalize by number of bins
        var low_count = low_end - low_start
        var mid_count = mid_end - low_end
        var high_count = high_end - mid_end

        self.low_freq = (
            low_energy / Float32(low_count) if low_count > 0 else 0.0
        )
        self.mid_freq = (
            mid_energy / Float32(mid_count) if mid_count > 0 else 0.0
        )
        self.high_freq = (
            high_energy / Float32(high_count) if high_count > 0 else 0.0
        )


fn compile_shader(type: UInt32, mut source: String) raises -> UInt32:
    var shader = gl_create_shader(type)
    var ptr = source.unsafe_cstr_ptr()
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
    var width: Int
    var height: Int
    var shader_program: UInt32
    var vao: UInt32
    var vbo: UInt32
    var animation_time: Float32
    var audio: AudioAnalyzer
    var low_freq: Float32
    var mid_freq: Float32
    var high_freq: Float32

    fn __init__(out self, width: Int, height: Int) raises:
        self.width = width
        self.height = height
        self.shader_program = 0
        self.vao = 0
        self.vbo = 0
        self.animation_time = 0.0
        self.audio = AudioAnalyzer()
        self.low_freq = 0.0
        self.mid_freq = 0.0
        self.high_freq = 0.0

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
        uniform vec2 resolution;
        void main() {
            vec2 rectCoord = TexCoord * resolution;
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

        var title = "Shimmer"
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
            size_of[type_of(vertices)](),
            vertices.unsafe_ptr().bitcast[NoneType](),
            GL_STATIC_DRAW,
        )

        var ebo = UInt32(0)
        gl_gen_buffers(1, UnsafePointer(to=ebo))
        gl_bind_buffer(GL_ELEMENT_ARRAY_BUFFER, ebo)
        gl_buffer_data(
            GL_ELEMENT_ARRAY_BUFFER,
            size_of[type_of(indices)](),
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

    fn update_viewport(mut self):
        gl_viewport(0, 0, self.width, self.height)

        gl_use_program(self.shader_program)
        var res_string = "resolution"
        var res_uniform = gl_get_uniform_location(
            self.shader_program, res_string.unsafe_cstr_ptr()
        )
        gl_uniform2f(res_uniform, Float32(self.width), Float32(self.height))

    fn run(mut self) raises:
        with DeviceContext() as ctx:
            var tex = GPUTexture(width=self.width, height=self.height, ctx=ctx)

            var buf = ctx.enqueue_create_buffer[DType.uint32](
                tex.width * tex.height
            )
            var alt_buf = ctx.enqueue_create_buffer[DType.uint32](
                tex.width * tex.height
            )

            var handle = DLHandle("libshader.dylib")
            var run_func = handle.get_function[
                fn (
                    mut DeviceBuffer[DType.uint32],
                    Uniforms,
                    DeviceContext,
                ) -> None
            ]("run_shader")

            var last_mod_time = stat(
                "libshader.dylib"
            ).st_mtimespec.as_nanoseconds()
            var last_check_time = perf_counter()
            var check_interval = 0.1

            self.update_viewport()

            while not glfw_window_should_close(self.window):
                glfw_poll_events()

                var fb_width = Int32(0)
                var fb_height = Int32(0)
                glfw_get_framebuffer_size(
                    self.window,
                    UnsafePointer(to=fb_width),
                    UnsafePointer(to=fb_height),
                )

                if Int(fb_width) != self.width or Int(fb_height) != self.height:
                    self.width = Int(fb_width)
                    self.height = Int(fb_height)
                    self.update_viewport()
                    tex = GPUTexture(
                        width=self.width, height=self.height, ctx=ctx
                    )
                    buf = ctx.enqueue_create_buffer[DType.uint32](
                        self.width * self.height
                    )

                if glfw_get_key(self.window, GLFW_KEY_ESCAPE) == GLFW_PRESS:
                    glfw_set_window_should_close(self.window, GLFW_TRUE)
                if glfw_get_key(self.window, GLFW_KEY_R) == GLFW_PRESS:
                    self.animation_time = 0

                # Update audio analysis
                self.audio.update()
                self.low_freq = self.audio.low_freq
                self.mid_freq = self.audio.mid_freq
                self.high_freq = self.audio.high_freq

                var current_time = perf_counter()
                if current_time - last_check_time > check_interval:
                    last_check_time = current_time
                    var current_mod_time = stat(
                        "libshader.dylib"
                    ).st_mtimespec.as_nanoseconds()
                    if current_mod_time != last_mod_time:
                        last_mod_time = current_mod_time
                        sleep(0.1)
                        handle = DLHandle("libshader.dylib")
                        run_func = handle.get_function[
                            fn (
                                mut DeviceBuffer[DType.uint32],
                                Uniforms,
                                DeviceContext,
                            ) -> None
                        ]("run_shader")

                run_func(
                    buf,
                    Uniforms(
                        self.width,
                        self.height,
                        self.animation_time,
                        Vec3(
                            self.low_freq,
                            self.mid_freq,
                            self.high_freq,
                        ),
                    ),
                    ctx,
                )
                tex.copy_from(buf, ctx)
                ctx.synchronize()

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
    var app = App(640, 480)
    app.run()
    glfw_terminate()
