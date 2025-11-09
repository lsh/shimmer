import wgpu
from shimmer import App, Context, Update, Event, Frame

from gpu.host import DeviceContext
from memory import ArcPointer, memcpy
import sys


@fieldwise_init
struct Vertex(Copyable, ImplicitlyCopyable, Movable):
    var x: Float32
    var y: Float32


alias vertices: InlineArray[Vertex, 3] = [
    {-0.5, -0.25},
    {0.0, 0.5},
    {0.25, -0.1},
]


fn as_bytes[T: Copyable & Movable](span: Span[T]) -> Span[UInt8, span.origin]:
    return Span[UInt8, span.origin](
        ptr=span.unsafe_ptr().bitcast[UInt8](),
        length=len(span) * sys.size_of[T](),
    )


@fieldwise_init
struct Model(Movable):
    var device_ctx: DeviceContext
    var render_pipeline: wgpu.RenderPipeline
    var vertex_buffer: wgpu.Buffer


fn model(ctx: Context) raises -> Model:
    try:
        with DeviceContext() as device_ctx:
            # The gpu device associated with the window's swapchain
            # let window = app.window(w_id).unwrap();
            var device = ctx.window.device
            # var format = Frame.TEXTURE_FORMAT
            # let sample_count = window.msaa_samples();

            # // Load shader modules.
            var fs_desc = """@fragment
            fn main() -> @location(0) vec4<f32> {
                return vec4<f32>(1.0, 0.0, 0.0, 1.0);
            }"""
            var vs_desc = """@vertex
            fn main(@location(0) pos: vec2<f32>) -> @builtin(position) vec4<f32> {
                return vec4<f32>(pos, 0.0, 1.0);
            }
            """
            var fs_mod = device[].create_wgsl_shader_module(code=fs_desc)
            var vs_mod = device[].create_wgsl_shader_module(code=vs_desc)

            # Create the vertex buffer.
            var vertices_bytes = as_bytes(vertices)
            var usage = wgpu.BufferUsage.vertex
            var vertex_buffer = device[].create_buffer(
                {
                    label = "vertex buffer",
                    size = len(vertices_bytes),
                    usage = usage,
                    mapped_at_creation = True,
                }
            )
            memcpy(
                dest=vertex_buffer.get_mapped_range(
                    0, len(vertices_bytes)
                ).bitcast[UInt8](),
                src=vertices_bytes.unsafe_ptr(),
                count=len(vertices_bytes),
            )
            vertex_buffer.unmap()

            var vertex_attributes = [
                wgpu.VertexAttribute(
                    format=wgpu.VertexFormat.float32x2,
                    offset=0,
                    shader_location=0,
                )
            ]

            var vertex_buffer_layouts = [
                wgpu.VertexBufferLayout(
                    array_stride=sys.size_of[Vertex](),
                    step_mode=wgpu.VertexStepMode.vertex,
                    attributes=Span(vertex_attributes),
                )
            ]

            var bind_group_layouts = List[ArcPointer[wgpu.BindGroupLayout]]()
            var pipeline_layout = device[].create_pipeline_layout(
                {"pipeline layout", Span(bind_group_layouts)}
            )
            var targets = [
                wgpu.ColorTargetState(
                    blend=wgpu.BlendState(
                        color=wgpu.BlendComponent(
                            src_factor=wgpu.BlendFactor.src_alpha,
                            dst_factor=wgpu.BlendFactor.one_minus_src_alpha,
                            operation=wgpu.BlendOperation.add,
                        ),
                        alpha=wgpu.BlendComponent(
                            src_factor=wgpu.BlendFactor.zero,
                            dst_factor=wgpu.BlendFactor.one,
                            operation=wgpu.BlendOperation.add,
                        ),
                    ),
                    format=ctx.window.surface_conf.format,
                    write_mask=wgpu.ColorWriteMask.all,
                )
            ]

            pipeline = device[].create_render_pipeline(
                {
                    label = "render pipeline",
                    vertex = wgpu.VertexState(
                        entry_point="main",
                        module=vs_mod,
                        buffers=vertex_buffer_layouts,
                    ),
                    fragment = wgpu.FragmentState(
                        module=fs_mod,
                        entry_point="main",
                        targets=targets,
                    ),
                    primitive = wgpu.PrimitiveState(
                        topology=wgpu.PrimitiveTopology.triangle_list,
                    ),
                    multisample = wgpu.MultisampleState(),
                    layout = Pointer(to=pipeline_layout),
                    depth_stencil = None,
                }
            )

            return Model(
                device_ctx=device_ctx,
                vertex_buffer=vertex_buffer^,
                render_pipeline=pipeline^,
            )
    except:
        print("failed to create device context")
        while True:
            pass


fn update(ctx: Context, mut model: Model, var update: Update) raises:
    # print(ctx.time)
    pass


fn event(ctx: Context, mut model: Model, var event: Event) raises:
    if event.is_window_event() and event.get_window_event().is_resized():
        print(event)


fn view(ctx: Context, model: Model, var frame: Frame) raises:
    ref encoder = frame.command_encoder()
    var color_attachments = [
        wgpu.RenderPassColorAttachment(
            view=frame.texture_view(),
            load_op=wgpu.LoadOp.clear,
            store_op=wgpu.StoreOp.store,
            clear_value=wgpu.Color(0.9, 0.1, 0.2, 1.0),
        )
    ]

    var rp = encoder.begin_render_pass(color_attachments=color_attachments)
    rp.set_pipeline(model.render_pipeline)
    rp.set_vertex_buffer(
        0, 0, model.vertex_buffer.get_size(), model.vertex_buffer
    )
    rp.draw(3, 1, 0, 0)
    rp.end()  # Move into end() to consume it

    frame.submit()  # Explicitly submit before frame goes out of scope


fn main() raises:
    var app = App[model, update_fn=update, event_fn=event, view_fn=view]()
    app^.run()
