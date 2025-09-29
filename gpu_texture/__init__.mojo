from gl import *

from gpu.host import DeviceContext, DeviceBuffer
from memory import memcpy
from sys.info import size_of


struct GPUTexture:
    var gl_texture: UInt32
    var gl_texture_target: UInt32
    var width: Int
    var height: Int
    var _pbo: UInt32

    fn __init__(
        out self,
        width: Int,
        height: Int,
        ctx: DeviceContext,
    ) raises:
        self.gl_texture = 0
        self.gl_texture_target = GL_TEXTURE_RECTANGLE
        self.width = width
        self.height = height
        self._pbo = 0

        gl_gen_textures(1, UnsafePointer(to=self.gl_texture))
        gl_bind_texture(self.gl_texture_target, self.gl_texture)
        gl_tex_parameteri(
            self.gl_texture_target, GL_TEXTURE_MIN_FILTER, GL_LINEAR
        )
        gl_tex_parameteri(
            self.gl_texture_target, GL_TEXTURE_MAG_FILTER, GL_LINEAR
        )

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

        gl_gen_buffers(1, UnsafePointer(to=self._pbo))
        gl_bind_buffer(GL_PIXEL_UNPACK_BUFFER, self._pbo)
        gl_buffer_data(
            GL_PIXEL_UNPACK_BUFFER, width * height * 4, {}, GL_DYNAMIC_DRAW
        )
        gl_bind_buffer(GL_PIXEL_UNPACK_BUFFER, 0)

    fn copy_from[
        dtype: DType
    ](mut self, buffer: DeviceBuffer[dtype], ctx: DeviceContext) raises:
        with buffer.map_to_host() as mapped:
            gl_bind_buffer(GL_PIXEL_UNPACK_BUFFER, self._pbo)
            var pbo_ptr = gl_map_buffer(GL_PIXEL_UNPACK_BUFFER, GL_WRITE_ONLY)
            if pbo_ptr:
                var src = mapped.unsafe_ptr().bitcast[UInt8]()
                var dst = pbo_ptr.bitcast[UInt8]()
                memcpy(dst, src, self.width * self.height * 4)
                _ = gl_unmap_buffer(GL_PIXEL_UNPACK_BUFFER)

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
                {},
            )
            gl_bind_buffer(GL_PIXEL_UNPACK_BUFFER, 0)

    fn __del__(deinit self):
        if self.gl_texture != 0:
            gl_delete_textures(1, UnsafePointer(to=self.gl_texture))
        if self._pbo != 0:
            gl_delete_buffers(1, UnsafePointer(to=self._pbo))
