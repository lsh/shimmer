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

    fn texture_view(ref self) -> ArcPointer[wgpu.TextureView]:
        return self._raw_frame._swap_chain_texture

    fn submit(deinit self):
        self._raw_frame^.submit()

    fn command_encoder(
        ref self,
    ) -> ref [self._raw_frame._command_encoder] wgpu.CommandEncoder:
        return self._raw_frame._command_encoder
