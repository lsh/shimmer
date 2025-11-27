from ._time import Instant, Duration
from .event import WindowEvent, Event, LoopEvent, Update
from .frame import Frame
from .state import Time
from .window import Window

from shimmer.geom import Vec2
import wgpu

from memory import ArcPointer
from utils import Variant


alias ModelFn[Model: Movable] = fn (Context) raises -> Model
"""
The user function type for initialising their model.
"""

alias EventFn[Model: Movable, Event: Movable] = fn (
    Context, mut Model, var Event
) raises -> None
"""
The user function type for updating their model in accordance with some event.
"""

alias UpdateFn[Model: Movable] = fn (
    Context, mut Model, var Update
) raises -> None
"""
The user function type for updating the user model within the application loop.
"""

alias ViewFn[Model: Movable] = fn (Context, Model, var Frame) raises -> None
"""
The user function type for drawing their model to the surface of a single window.
"""

alias SketchViewFn = fn (Context, var Frame) raises -> None
"""
A shorthand version of `ViewFn` for sketches where the user does not need a model.
"""

alias ExitFn[Model: Movable] = fn (Context, var Model) raises -> None
"""
The user function type allowing them to consume the `model` when the application exits.
"""


struct Context:
    alias ASSETS_DIRECTORY_NAME: StaticString = "assets"
    alias DEFAULT_EXIT_ON_ESCAPE: Bool = True
    alias DEFAULT_FULLSCREEN_ON_SHORTCUT: Bool = True

    var config: Config
    var window: Window
    var _backends: wgpu.InstanceBackend
    var _instance: wgpu.Instance
    var _adapter: wgpu.Adapter
    var duration: Time
    var time: Float32

    fn __init__(out self) raises:
        self.time = 0.0
        var title = "Shimmer"
        self.config = {}
        self.duration = {}
        self._backends = wgpu.InstanceBackend.metal
        self._instance = wgpu.Instance()

        # Create window first
        glfw.Window.default_hints()
        glfw.Window.hint(glfw.ContextHint.client_api, glfw.ContextHint.no_api)
        var glfw_window = glfw.Window(640, 480, title)

        # Create surface BEFORE moving the window (surface needs the window handle)
        var surface = self._instance.create_surface(glfw_window)

        # Request adapter WITH surface so it knows about surface capabilities
        self._adapter = self._instance.request_adapter_sync(surface)

        # Now create the Window with the adapter and surface (moving window and surface)
        self.window = Window(
            self._instance, self._adapter, glfw_window^, surface^, 640, 480
        )

    @always_inline
    fn loop_mode(self) -> LoopMode:
        return self.config.loop_mode.copy()


@fieldwise_init
struct Config(Copyable, Movable):
    """
    Miscellaneous app configuration parameters.
    """

    var loop_mode: LoopMode
    var exit_on_escape: Bool
    var fullscreen_on_shortcut: Bool

    fn __init__(out self):
        self.loop_mode = {}
        self.exit_on_escape = Context.DEFAULT_EXIT_ON_ESCAPE
        self.fullscreen_on_shortcut = Context.DEFAULT_FULLSCREEN_ON_SHORTCUT


struct App[
    ModelType: Movable, //,
    model_fn: ModelFn[ModelType],
    EventType: LoopEvent = Event,
    update_fn: Optional[UpdateFn[ModelType]] = None,
    event_fn: Optional[EventFn[ModelType, EventType]] = None,
    view_fn: Optional[ViewFn[ModelType]] = None,
    exit_fn: Optional[ExitFn[ModelType]] = None,
]:
    fn __init__(out self) raises:
        glfw.init()

        fn error_cb(code: Int32, msg: UnsafePointer[Int8]):
            print("GLFW_ERR:", code, StringSlice(unsafe_from_utf8_ptr=msg))

    fn run(var self) raises:
        var ctx = Context()
        var model = Self.model_fn(ctx)

        var model_ctx = (
            wgpu._cffi.FFIPointer[mut=True](UnsafePointer(to=ctx)),
            wgpu._cffi.FFIPointer[mut=True](UnsafePointer(to=model)),
        )
        ctx.window.inner.set_user_pointer[
            Tuple[
                wgpu._cffi.FFIPointer[Context, mut=True],
                wgpu._cffi.FFIPointer[Self.ModelType, mut=True],
            ]
        ](UnsafePointer(to=model_ctx))

        fn resize_cb(window: glfw.Window, width: Int32, height: Int32):
            var ctx_ptr, model_ptr = window.get_user_pointer[
                Tuple[
                    wgpu._cffi.FFIPointer[Context, mut=True],
                    wgpu._cffi.FFIPointer[Self.ModelType, mut=True],
                ]
            ]()[]
            if Self.event_fn:
                try:
                    ctx_ptr.unsafe_ptr()[].window.surface_conf.width = Int(
                        width
                    )
                    ctx_ptr.unsafe_ptr()[].window.surface_conf.height = Int(
                        height
                    )
                    ctx_ptr.unsafe_ptr()[].window.surface.configure(
                        ctx_ptr.unsafe_ptr()[].window.device[],
                        ctx_ptr.unsafe_ptr()[].window.surface_conf,
                    )
                    Self.event_fn.value()(
                        ctx_ptr.unsafe_ptr()[],
                        model_ptr.unsafe_ptr()[],
                        Self.EventType(
                            WindowEvent.resized(
                                Vec2(Float32(width), Float32(height))
                            )
                        ),
                    )
                except:
                    pass

        ctx.window.inner.set_size_callback[resize_cb]()
        run_loop[
            EventType = Self.EventType,
            exit_fn = Self.exit_fn,
            update_fn = Self.update_fn,
            event_fn = Self.event_fn,
            view_fn = Self.view_fn,
        ](ctx, model^)
        _ = model_ctx
        glfw.terminate()


# State related specifically to the application loop, shared between loop modes.
@fieldwise_init
struct LoopState(Copyable, ImplicitlyCopyable, Movable):
    var updates_since_event: UInt64
    var loop_start: Instant
    var last_update: Instant
    var total_updates: UInt64


@fieldwise_init
struct _Rate(Copyable, ImplicitlyCopyable, Movable):
    var update_interval: Duration
    """
    The minimum interval between emitted updates.
    """


@fieldwise_init
struct _RefreshSync(Copyable, ImplicitlyCopyable, Movable):
    pass


@fieldwise_init
struct _Wait(Copyable, ImplicitlyCopyable, Movable):
    pass


@always_inline
fn update_interval(fps: Float64) -> Duration:
    debug_assert(fps > 0.0)
    alias NANOSEC_PER_SEC: Float64 = 1_000_000_000.0
    var interval_nanosecs = NANOSEC_PER_SEC / fps
    var secs = UInt64(interval_nanosecs / NANOSEC_PER_SEC)
    var nanosecs = UInt32(interval_nanosecs % NANOSEC_PER_SEC)
    return Duration(secs, nanosecs)


@fieldwise_init
struct _NTimes(Copyable, ImplicitlyCopyable, Movable):
    var number_of_updates: Int


struct LoopMode(Copyable, Movable):
    """
    The mode in which the **Context** is currently running the event loop and emitting `Update` events.
    """

    alias DEFAULT_RATE_FPS: Float64 = 60.0
    alias UPDATES_PER_WAIT_EVENT: UInt32 = 3
    """
    The minimum number of updates that will be emitted after an event is triggered in Wait
    mode.
    """

    var _value: Variant[_Rate, _RefreshSync, _Wait, _NTimes]

    fn __init__(out self):
        self = Self.refresh_sync()

    fn __init__(out self, value: _Rate):
        self._value = value

    fn __init__(out self, value: _RefreshSync):
        self._value = value

    fn __init__(out self, value: _Wait):
        self._value = value

    fn __init__(out self, value: _NTimes):
        self._value = value

    @staticmethod
    fn rate_fps(fps: Float64) -> Self:
        """
        Specify the **Rate** mode with the given frames-per-second.
        """
        return Self(_Rate(update_interval(fps)))

    @staticmethod
    fn refresh_sync() -> Self:
        return Self(_RefreshSync())

    @staticmethod
    fn wait() -> Self:
        return Self(_Wait())

    @staticmethod
    fn loop_ntimes(number_of_updates: Int) -> Self:
        return Self(_NTimes(number_of_updates))

    @staticmethod
    fn loop_once() -> Self:
        return Self.loop_ntimes(1)

    @always_inline
    fn is_ntimes(self) -> Bool:
        return self._value.isa[_NTimes]()

    @always_inline
    fn is_wait(self) -> Bool:
        return self._value.isa[_Wait]()

    @always_inline
    fn is_refresh_sync(self) -> Bool:
        return self._value.isa[_RefreshSync]()

    @always_inline
    fn is_rate(self) -> Bool:
        return self._value.isa[_Rate]()

    @always_inline
    fn get_ntimes(self) -> ref [self._value] _NTimes:
        return self._value[_NTimes]

    @always_inline
    fn get_wait(self) -> ref [self._value] _Wait:
        return self._value[_Wait]

    @always_inline
    fn get_refresh_sync(self) -> ref [self._value] _RefreshSync:
        return self._value[_RefreshSync]

    @always_inline
    fn get_rate(self) -> _Rate:
        return self._value[_Rate]


fn run_loop[
    ModelType: Movable,
    EventType: LoopEvent = Event,
    model_fn: Optional[ModelFn[ModelType]] = None,
    update_fn: Optional[UpdateFn[ModelType]] = None,
    event_fn: Optional[EventFn[ModelType, EventType]] = None,
    view_fn: Optional[ViewFn[ModelType]] = None,
    exit_fn: Optional[ExitFn[ModelType]] = None,
](mut ctx: Context, var model: ModelType) raises:
    # Track the moment the loop starts.
    var loop_start = Instant.now()

    # Keep track of state related to the loop mode itself.
    var loop_state = LoopState(
        updates_since_event=0,
        loop_start=loop_start,
        last_update=loop_start,
        total_updates=0,
    )

    # Run the event loop.
    while not ctx.window.should_close():
        glfw.poll_events()

        var now = Instant.now()

        @parameter
        fn do_update(
            mut loop_state: LoopState,
        ) raises:
            apply_update[
                ModelType, EventType, event_fn=event_fn, update_fn=update_fn
            ](ctx, model, loop_state, now)

        var loop_mode = ctx.loop_mode()
        if loop_mode.is_ntimes():
            var number_of_updates = loop_mode.get_ntimes().number_of_updates
            if loop_state.total_updates >= number_of_updates:
                pass
        elif loop_mode.is_wait() and loop_state.updates_since_event > 0:
            pass
        elif loop_mode.is_wait():
            pass
        else:
            do_update(loop_state)

        var nth_frame = ctx.window.frame_count

        with ctx.window.surface.get_current_texture() as surface_tex:
            var surface_texture = surface_tex.texture.create_view(
                {
                    format = surface_tex.texture.get_format(),
                    dimension = wgpu.TextureViewDimension.d2,
                    base_mip_level = 0,
                    mip_level_count = 1,
                    base_array_layer = 0,
                    array_layer_count = 1,
                    aspect = wgpu.TextureAspect.all,
                }
            )

            var w, h = ctx.window.inner.get_size()
            var window_rect = shimmer.geom.Rect(
                width=Float32(w), height=Float32(h)
            )
            var raw_frame = shimmer.frame.RawFrame(
                ctx.window.device,
                ctx.window.queue,
                nth_frame,
                ArcPointer(surface_texture^),
                ctx.window.surface_conf.format,
                window_rect,
            )

            if view_fn:
                view_fn.value()(ctx, model, Frame(raw_frame^))
            else:
                raw_frame^.submit()

            ctx.window.surface.present()

        ctx.window.frame_count += 1

    if exit_fn:
        exit_fn.value()(ctx, model^)


fn apply_update[
    ModelType: Movable,
    EventType: LoopEvent,
    update_fn: Optional[UpdateFn[ModelType]] = None,
    event_fn: Optional[EventFn[ModelType, EventType]] = None,
](
    mut ctx: Context,
    mut model: ModelType,
    mut loop_state: LoopState,
    now: Instant,
) raises:
    # // Update the app's durations.
    var since_last = now.duration_since(loop_state.last_update)
    var since_start = now.duration_since(loop_state.loop_start)
    ctx.duration.since_prev_update = since_last
    ctx.duration.since_start = since_start
    ctx.time = Float32(since_start.secs())
    var update = Update(since_start=since_start, since_last=since_last)
    # User event function.
    if event_fn:
        event_fn.value()(ctx, model, EventType(update.copy()))
    # User update function.
    if update_fn:
        update_fn.value()(ctx, model, update^)
    loop_state.last_update = now
    loop_state.total_updates += 1
    loop_state.updates_since_event += 1
