import wgpu

from memory import ArcPointer


struct RawFrame(Movable):
    var _command_encoder: wgpu.CommandEncoder
    var _nth: UInt64
    var _swap_chain_texture: ArcPointer[wgpu.TextureView]
    var _device: ArcPointer[wgpu.Device]
    var _queue: ArcPointer[wgpu.Queue]
    var _texture_format: wgpu.TextureFormat
    var _window_rect: shimmer.geom.Rect

    fn __init__(
        out self,
        device: ArcPointer[wgpu.Device],
        queue: ArcPointer[wgpu.Queue],
        nth: UInt64,
        swap_chain_texture: ArcPointer[wgpu.TextureView],
        texture_format: wgpu.TextureFormat,
        window_rect: shimmer.geom.Rect[],
    ):
        self._command_encoder = device[].create_command_encoder({})
        self._nth = nth
        self._queue = queue
        self._device = device
        self._swap_chain_texture = swap_chain_texture
        self._texture_format = texture_format
        self._window_rect = window_rect

    fn submit(deinit self):
        var command_buffer = self._command_encoder^.finish()
        self._queue[].submit(command_buffer^)

    fn __del__(deinit self):
        var command_buffer = self._command_encoder^.finish()
        self._queue[].submit(command_buffer^)
