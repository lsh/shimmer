from cuda_gl_interop import *
from gl import *
from gl._metal import (
    nsgl_context_get_cgl_context,
    AAPLOpenGLMetalInteropTexture,
)
from glfw import GLFWwindow, glfw_get_ns_gl_context

from gpu.host import DeviceContext, DeviceBuffer
from gpu.host._metal import metal_device
from sys import has_apple_gpu_accelerator, has_nvidia_gpu_accelerator
from sys.info import size_of


struct GPUTexture:
    var gl_texture: UInt32
    var gl_texture_target: UInt32
    var width: Int
    var height: Int
    var _cuda_pbo_resource: UnsafePointer[cudaGraphicsResource]
    var _pbo: UInt32

    fn __init__(
        out self,
        width: Int,
        height: Int,
        window: UnsafePointer[GLFWwindow],
        ctx: DeviceContext,
    ) raises:
        self.gl_texture = 0
        self.gl_texture_target = GL_TEXTURE_RECTANGLE
        self.width = width
        self.height = height

        self._cuda_pbo_resource = {}
        self._pbo = 0

        # Create OpenGL texture
        gl_gen_textures(1, UnsafePointer(to=self.gl_texture))
        gl_bind_texture(self.gl_texture_target, self.gl_texture)

        # Set texture parameters for GL_TEXTURE_RECTANGLE
        gl_tex_parameteri(
            self.gl_texture_target, GL_TEXTURE_MIN_FILTER, GL_LINEAR
        )
        gl_tex_parameteri(
            self.gl_texture_target, GL_TEXTURE_MAG_FILTER, GL_LINEAR
        )

        # Allocate texture storage
        gl_tex_image_2d(
            self.gl_texture_target,
            0,
            GL_RGBA8,
            width,
            height,
            0,
            GL_BGRA,
            GL_UNSIGNED_BYTE,
            {},
        )

        @parameter
        if has_apple_gpu_accelerator():
            # Create Pixel Buffer Object for GPU interop
            gl_gen_buffers(1, UnsafePointer(to=self._pbo))
            gl_bind_buffer(GL_PIXEL_UNPACK_BUFFER, self._pbo)
            gl_buffer_data(
                GL_PIXEL_UNPACK_BUFFER, width * height * 4, {}, GL_DYNAMIC_DRAW
            )
            gl_bind_buffer(GL_PIXEL_UNPACK_BUFFER, 0)

            var nsgl_context = glfw_get_ns_gl_context(window)
            var cgl_context = nsgl_context_get_cgl_context(nsgl_context)

            # var tex = AAPLOpenGLMetalInteropTexture(
            #     mtl_device=metal_device(ctx).bitcast[NoneType](),
            #     gl_context=cgl_context.bitcast[NoneType](),
            #     mtl_pixel_format=MTLPixelFormatBGRA8Unorm,
            #     size=CGSize(width=640, height=480),
            # )
        elif has_nvidia_gpu_accelerator():
            # Create Pixel Buffer Object for GPU interop
            gl_gen_buffers(1, UnsafePointer(to=self._pbo))
            gl_bind_buffer(GL_PIXEL_UNPACK_BUFFER, self._pbo)
            gl_buffer_data(
                GL_PIXEL_UNPACK_BUFFER, width * height * 4, {}, GL_DYNAMIC_DRAW
            )
            gl_bind_buffer(GL_PIXEL_UNPACK_BUFFER, 0)
        else:
            constrained[False, "Unsupported GPU architecture"]()

    fn copy_from[
        dtype: DType
    ](mut self, buffer: DeviceBuffer[dtype], ctx: DeviceContext) raises:
        @parameter
        if has_apple_gpu_accelerator():
            # For Apple GPU, we need to copy data to PBO then update texture
            # First map the buffer to host memory
            with buffer.map_to_host() as mapped:
                # Bind PBO and copy data to it
                gl_bind_buffer(GL_PIXEL_UNPACK_BUFFER, self._pbo)
                var pbo_ptr = gl_map_buffer(
                    GL_PIXEL_UNPACK_BUFFER, GL_WRITE_ONLY
                )
                if pbo_ptr:
                    # Copy data from mapped buffer to PBO
                    var src = mapped.unsafe_ptr().bitcast[UInt8]()
                    var dst = pbo_ptr.bitcast[UInt8]()
                    for i in range(self.width * self.height * 4):
                        dst[i] = src[i]
                    _ = gl_unmap_buffer(GL_PIXEL_UNPACK_BUFFER)

                # Update texture from PBO
                gl_bind_texture(self.gl_texture_target, self.gl_texture)
                gl_tex_sub_image_2d(
                    self.gl_texture_target,
                    0,
                    0,
                    0,
                    self.width,
                    self.height,
                    GL_BGRA,
                    GL_UNSIGNED_BYTE,
                    {},  # NULL because we're using PBO
                )
                gl_bind_buffer(GL_PIXEL_UNPACK_BUFFER, 0)
        elif has_nvidia_gpu_accelerator():
            # For NVIDIA, copy data directly to texture without CUDA interop
            with buffer.map_to_host() as mapped:
                gl_bind_texture(self.gl_texture_target, self.gl_texture)
                gl_tex_sub_image_2d(
                    self.gl_texture_target,
                    0,
                    0,
                    0,
                    self.width,
                    self.height,
                    GL_BGRA,
                    GL_UNSIGNED_BYTE,
                    mapped.unsafe_ptr().bitcast[NoneType](),
                )
        else:
            constrained[False, "Unsupported GPU architecture"]()

    fn __del__(deinit self):
        # Clean up OpenGL resources
        if self.gl_texture != 0:
            gl_delete_textures(1, UnsafePointer(to=self.gl_texture))
        if self._pbo != 0:
            gl_delete_buffers(1, UnsafePointer(to=self._pbo))

        @parameter
        if has_apple_gpu_accelerator():
            pass
        elif has_nvidia_gpu_accelerator():
            pass
