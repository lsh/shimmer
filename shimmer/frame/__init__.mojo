from memory import ArcPointer

import wgpu

from .raw import RawFrame


@fieldwise_init
struct Frame(Movable):
    var _raw_frame: RawFrame

    alias DEFAULT_MSAA_SAMPLES: UInt32 = 4
    """
    The default number of multisample anti-aliasing samples used if the window with which the
    `Frame` is associated supports it.
    """

    fn _submit_inner(mut self):
        self._raw_frame._submit_inner()

    fn texture_view(ref self) -> ArcPointer[wgpu.TextureView]:
        return self._raw_frame._swap_chain_texture

    fn submit(mut self):
        self._submit_inner()

    fn command_encoder(
        ref self,
    ) raises -> ref [
        self._raw_frame._command_encoder._value
    ] wgpu.CommandEncoder:
        return self._raw_frame._command_encoder[][]

    fn __del__(deinit self):
        if not self._raw_frame.is_submitted():
            self._submit_inner()
