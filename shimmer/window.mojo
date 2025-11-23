import glfw
import wgpu

from memory import ArcPointer


@fieldwise_init
struct Window:
    var inner: glfw.Window
    var msaa_samples: UInt32
    var frame_count: UInt64
    var clear_color: wgpu.Color
    var device: ArcPointer[wgpu.Device]
    var queue: ArcPointer[wgpu.Queue]
    var surface: wgpu.Surface
    var surface_conf: wgpu.SurfaceConfiguration

    fn __init__(
        out self,
        instance: wgpu.Instance,
        adapter: wgpu.Adapter,
        var glfw_window: glfw.Window,
        var surface: wgpu.Surface,
        width: Int,
        height: Int,
    ) raises:
        self.inner = glfw_window^
        self.msaa_samples = 0
        self.frame_count = 0
        self.clear_color = wgpu.Color()
        self.device = ArcPointer(adapter.request_device({}))
        self.queue = ArcPointer(self.device[].get_queue())
        self.surface = surface^
        var surface_capabilities = self.surface.get_capabilities(adapter)
        var formats = surface_capabilities.formats()
        if len(formats) == 0:
            raise Error("No surface formats available")
        var surface_format = formats[0]
        self.surface_conf = wgpu.SurfaceConfiguration(
            width=width,
            height=height,
            usage=wgpu.TextureUsage.render_attachment,
            format=surface_format,
            alpha_mode=wgpu.CompositeAlphaMode.auto,
            present_mode=wgpu.PresentMode.fifo,
            view_formats=List[wgpu.TextureFormat](),
        )
        self.surface.configure(self.device[], self.surface_conf)

    fn should_close(self) -> Bool:
        return self.inner.should_close()
