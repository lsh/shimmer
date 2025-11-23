import wgpu
from shimmer import App, Context, Update, Event, Frame
from shimmer.geom import Vec2, Vec3, Mat4

from builtin.device_passable import DevicePassable
from gpu.host import DeviceContext, DeviceBuffer
from gpu import global_idx
from hashlib.hasher import Hasher
import math
from memory import ArcPointer, memcpy
from random import random_float64, random_ui64
import sys


fn mix(x: Float32, y: Float32, a: Float32) -> Float32:
    return x * (1.0 - a) + y * a


fn mix(x: Vec3, y: Vec3, a: Float32) -> Vec3:
    return {
        mix(x.x, y.x, a),
        mix(x.y, y.y, a),
        mix(x.z, y.z, a),
    }


@fieldwise_init
struct Uniforms(Copyable, DevicePassable, ImplicitlyCopyable, Movable):
    var width: Int
    var height: Int
    var time: Float32

    comptime device_type: AnyType = Self

    fn _to_device_type(self, target: LegacyOpaquePointer):
        target.bitcast[Self.device_type]()[] = self

    @staticmethod
    fn get_type_name() -> String:
        return "Uniforms"

    @staticmethod
    fn get_device_type_name() -> String:
        return Self.get_type_name()


@fieldwise_init
struct Vertex(Copyable, ImplicitlyCopyable, Movable):
    var position: Vec3
    var uv: Vec2


@fieldwise_init
struct Model(Movable):
    var device_ctx: DeviceContext
    var render_pipeline: wgpu.RenderPipeline
    var texture_data: DeviceBuffer[DType.uint8]
    var vertex_buffer: wgpu.Buffer
    var index_buffer: wgpu.Buffer
    var num_indices: Int
    var uniform_bind_group: wgpu.BindGroup
    var uniform_buffer: wgpu.Buffer
    var uniforms: Uniforms
    var texture: wgpu.Texture
    var texture_view: wgpu.TextureView
    var texture_sampler: wgpu.Sampler


fn model(ctx: Context) raises -> Model:
    try:
        with DeviceContext() as device_ctx:
            var device = ctx.window.device

            var verts: InlineArray[Vertex, 4] = [
                {{-1.0, -1.0, 0.0}, {0.0, 1.0}},
                {{1.0, -1.0, 0.0}, {1.0, 1.0}},
                {{1.0, 1.0, 0.0}, {1.0, 0.0}},
                {{-1.0, 1.0, 0.0}, {0.0, 0.0}},
            ]
            var faces: InlineArray[UInt32, 6] = [0, 1, 2, 0, 2, 3]

            var vs_desc = """
            struct Uniforms {
                time: f32,
            }

            @group(0) @binding(0)
            var<uniform> uniforms: Uniforms;

            struct VertexInput {
                @location(0) position: vec3<f32>,
                @location(1) uv: vec2<f32>,
            }

            struct VertexOutput {
                @builtin(position) clip_position: vec4<f32>,
                @location(0) uv: vec2<f32>,
            }

            @vertex
            fn main(model: VertexInput) -> VertexOutput {
                var out: VertexOutput;
                out.clip_position = vec4<f32>(model.position, 1.0);
                out.uv = model.uv;
                return out;
            }
            """

            var fs_desc = """
            struct Uniforms {
                time: f32,
            }

            @group(0) @binding(0)
            var<uniform> uniforms: Uniforms;

            @group(0) @binding(1)
            var t_texture: texture_2d<f32>;

            @group(0) @binding(2)
            var t_sampler: sampler;

            struct VertexOutput {
                @builtin(position) clip_position: vec4<f32>,
                @location(0) uv: vec2<f32>,
            }

            @fragment
            fn main(in: VertexOutput) -> @location(0) vec4<f32> {
                var color = textureSample(t_texture, t_sampler, in.uv);
                return color;
            }
            """
            var fs_mod = device[].create_wgsl_shader_module(code=fs_desc)
            var vs_mod = device[].create_wgsl_shader_module(code=vs_desc)

            var vertex_usage = (
                wgpu.BufferUsage.vertex | wgpu.BufferUsage.copy_dst
            )
            var vertex_buffer = device[].create_buffer[Vertex](
                {
                    label = "vertex buffer",
                    size = len(verts) * sys.size_of[Vertex](),
                    usage = vertex_usage,
                    mapped_at_creation = True,
                }
            )
            with vertex_buffer.get_mapped_range[Vertex](
                0, len(verts) * sys.size_of[Vertex]()
            ) as vertex_host:
                for i in range(len(verts)):
                    vertex_host[i] = verts[i]

            var vertex_attributes = [
                wgpu.VertexAttribute(
                    format=wgpu.VertexFormat.float32x3,
                    offset=0,
                    shader_location=0,
                ),
                wgpu.VertexAttribute(
                    format=wgpu.VertexFormat.float32x2,
                    offset=sys.size_of[Vec3](),
                    shader_location=1,
                ),
            ]

            var vertex_buffer_layouts = [
                wgpu.VertexBufferLayout(
                    array_stride=sys.size_of[Vertex](),
                    step_mode=wgpu.VertexStepMode.vertex,
                    attributes=vertex_attributes^,
                ),
            ]

            var index_usage = wgpu.BufferUsage.index | wgpu.BufferUsage.copy_dst
            var index_buffer = device[].create_buffer[UInt32](
                {
                    label = "index buffer",
                    size = len(faces) * sys.size_of[UInt32](),
                    usage = index_usage,
                    mapped_at_creation = True,
                }
            )
            with index_buffer.get_mapped_range[UInt32](
                0, len(faces) * sys.size_of[UInt32]()
            ) as index_host:
                for i in range(len(faces)):
                    index_host[i] = faces[i]

            var bind_group_entries = [
                wgpu.BindGroupLayoutEntry(
                    binding=0,
                    visibility=wgpu.ShaderStage.fragment
                    | wgpu.ShaderStage.vertex,
                    type=wgpu.BufferBindingLayout(
                        type=wgpu.BufferBindingType.uniform,
                        has_dynamic_offset=True,
                        min_binding_size=sys.size_of[Uniforms](),
                    ),
                    count=0,
                ),
                wgpu.BindGroupLayoutEntry(
                    binding=1,
                    visibility=wgpu.ShaderStage.fragment,
                    type=wgpu.TextureBindingLayout(
                        sample_type=wgpu.TextureSampleType.float,
                        view_dimension=wgpu.TextureViewDimension.d2,
                        multisampled=False,
                    ),
                    count=0,
                ),
                wgpu.BindGroupLayoutEntry(
                    binding=2,
                    visibility=wgpu.ShaderStage.fragment,
                    type=wgpu.SamplerBindingLayout(
                        type=wgpu.SamplerBindingType.filtering,
                    ),
                    count=0,
                ),
            ]
            var bind_group_layouts: List[ArcPointer[wgpu.BindGroupLayout]] = [
                ArcPointer(
                    device[].create_bind_group_layout(
                        {
                            "bind group layout",
                            bind_group_entries,
                        }
                    )
                )
            ]
            var pipeline_layout = device[].create_pipeline_layout(
                {"pipeline layout", bind_group_layouts}
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

            var pipeline = device[].create_render_pipeline(
                {
                    label = "fullscreen quad render pipeline",
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
                        cull_mode=wgpu.CullMode.none,
                    ),
                    multisample = wgpu.MultisampleState(),
                    layout = Pointer(to=pipeline_layout).get_immutable(),
                    depth_stencil = None,
                }
            )

            var uniform_buffer = device[].create_buffer[Uniforms](
                {
                    "uniform buffer",
                    wgpu.BufferUsage.uniform | wgpu.BufferUsage.copy_dst,
                    sys.size_of[Uniforms](),
                    True,
                }
            )
            var width = Int(ctx.window.surface_conf.width)
            var height = Int(ctx.window.surface_conf.height)
            var uniforms = Uniforms(time=0, width=width, height=height)
            with uniform_buffer.get_mapped_range[Uniforms](
                0, sys.size_of[Uniforms]()
            ) as uniform_host:
                uniform_host[0] = uniforms.copy()

            var texture = device[].create_texture(
                wgpu.TextureDescriptor(
                    label="fullscreen texture",
                    size=wgpu.Extent3D(
                        width=ctx.window.surface_conf.width,
                        height=ctx.window.surface_conf.height,
                        depth_or_array_layers=1,
                    ),
                    mip_level_count=1,
                    sample_count=1,
                    dimension=wgpu.TextureDimension.d2,
                    format=wgpu.TextureFormat.rgba8_unorm,
                    usage=wgpu.TextureUsage.texture_binding
                    | wgpu.TextureUsage.copy_dst
                    | wgpu.TextureUsage.render_attachment,
                    view_formats=List[wgpu.TextureFormat](),
                )
            )
            var texture_view = texture.create_view(
                wgpu.TextureViewDescriptor(
                    label="fullscreen texture view",
                    format=wgpu.TextureFormat.rgba8_unorm,
                    dimension=wgpu.TextureViewDimension.d2,
                    aspect=wgpu.TextureAspect.all,
                    base_mip_level=0,
                    mip_level_count=1,
                    base_array_layer=0,
                    array_layer_count=1,
                )
            )
            var texture_sampler = device[].create_sampler(
                wgpu.SamplerDescriptor(
                    label="fullscreen texture sampler",
                    address_mode_u=wgpu.AddressMode.clamp_to_edge,
                    address_mode_v=wgpu.AddressMode.clamp_to_edge,
                    address_mode_w=wgpu.AddressMode.clamp_to_edge,
                    mag_filter=wgpu.FilterMode.linear,
                    min_filter=wgpu.FilterMode.linear,
                    mipmap_filter=wgpu.MipmapFilterMode.nearest,
                    lod_min_clamp=0.0,
                    lod_max_clamp=32.0,
                    compare=wgpu.CompareFunction.undefined,
                    max_anisotropy=1,
                )
            )

            var texture_data = device_ctx.enqueue_create_buffer[DType.uint8](
                width * height * 4
            )

            with texture_data.map_to_host() as texture_host:
                ctx.window.queue[].write_texture(
                    wgpu.ImageCopyTexture(
                        texture=texture,
                        mip_level=0,
                        origin=wgpu.Origin3D(x=0, y=0, z=0),
                        aspect=wgpu.TextureAspect.all,
                    ),
                    Span[UInt8, origin_of(texture_host)](
                        ptr=UnsafePointer[UInt8, origin_of(texture_host)](
                            texture_host.unsafe_ptr()
                        ),
                        length=len(texture_host),
                    ),
                    wgpu.TextureDataLayout(
                        offset=0,
                        bytes_per_row=UInt32(width * 4),
                        rows_per_image=UInt32(height),
                    ),
                    wgpu.Extent3D(
                        width=UInt32(width),
                        height=UInt32(height),
                        depth_or_array_layers=1,
                    ),
                )

            comptime uniform_bind_group_origin = origin_of(
                texture_view, uniform_buffer, texture_sampler
            )
            uniform_bind_group_entries = [
                wgpu.BindGroupEntry[uniform_bind_group_origin](
                    0,
                    wgpu.BufferBinding[uniform_bind_group_origin](
                        uniform_buffer, 0, sys.size_of[Uniforms]()
                    ),
                ),
                wgpu.BindGroupEntry[uniform_bind_group_origin](1, texture_view),
                wgpu.BindGroupEntry[uniform_bind_group_origin](
                    2, texture_sampler
                ),
            ]
            uniform_bind_group = device[].create_bind_group(
                {
                    "bind group",
                    bind_group_layouts[0],
                    uniform_bind_group_entries,
                }
            )

            return Model(
                device_ctx=device_ctx,
                vertex_buffer=vertex_buffer^,
                index_buffer=index_buffer^,
                render_pipeline=pipeline^,
                num_indices=len(faces),
                uniform_bind_group=uniform_bind_group^,
                uniform_buffer=uniform_buffer^,
                uniforms=uniforms^,
                texture=texture^,
                texture_view=texture_view^,
                texture_sampler=texture_sampler^,
                texture_data=texture_data^,
            )
    except:
        print("failed to create device context")
        while True:
            pass


fn rot3d_x(p: Vec3, a: Float32) -> Vec3:
    """Rotate a 3D point around the X axis."""
    var c = math.cos(a)
    var s = math.sin(a)
    return {p.x, p.y * c - p.z * s, p.y * s + p.z * c}


fn rot3d_y(p: Vec3, a: Float32) -> Vec3:
    """Rotate a 3D point around the Y axis."""
    var c = math.cos(a)
    var s = math.sin(a)
    return {p.x * c + p.z * s, p.y, -p.x * s + p.z * c}


fn rot3d_z(p: Vec3, a: Float32) -> Vec3:
    """Rotate a 3D point around the Z axis."""
    var c = math.cos(a)
    var s = math.sin(a)
    return {p.x * c - p.y * s, p.x * s + p.y * c, p.z}


@always_inline
fn calc_normal[
    df: fn (var Vec3, Uniforms) -> Float32, eps: Float32 = 0.005
](p: Vec3, uniforms: Uniforms) -> Vec3:
    return Vec3(
        df(p + Vec3(eps, 0.0, 0.0), uniforms)
        - df(p - Vec3(eps, 0.0, 0.0), uniforms),
        df(p + Vec3(0.0, eps, 0.0), uniforms)
        - df(p - Vec3(0.0, eps, 0.0), uniforms),
        df(p + Vec3(0.0, 0.0, eps), uniforms)
        - df(p - Vec3(0.0, 0.0, eps), uniforms),
    ).normalize()


@always_inline
fn calc_cam(uv: Vec2, ro: Vec3, rd: Vec3, fov: Float32) -> Vec3:
    var cu = Vec3(0.0, 1.0, 0.0).normalize()
    var z = (cu - ro).normalize()
    var x = cu.cross(z).normalize()
    var y = z.cross(x)
    return (z + fov * uv.x * x + fov * uv.y * y).normalize()


@always_inline
fn trace[
    df: fn (var Vec3, Uniforms) -> Float32,
    far: Float32 = 20.0,
    eps: Float32 = 0.001,
](ro: Vec3, rd: Vec3, uniforms: Uniforms) -> Float32:
    var t = Float32(0)
    for _ in range(250):
        var p = ro + rd * t
        var m = df(p, uniforms)
        t += m * 0.75
        if t > far or m < eps:
            break
    return t


@always_inline
fn map(var p: Vec3, uniforms: Uniforms) -> Float32:
    var q = p
    p = rot3d_z(p, q.z * 0.1 + uniforms.time * 0.25)
    p = (p % 2.0) - 1.0
    return p.length() - 0.4  # - math.clamp(uniforms.audio.y, 0.0, 0.4)


fn main_image[far: Float32 = 20.0](uv: Vec2, uniforms: Uniforms) -> Vec3:
    var q = uv * 2.0 - 1.0
    (UnsafePointer(to=q).bitcast[Float32]())[] *= Float32(
        uniforms.width
    ) / Float32(uniforms.height)
    var ro = Vec3(0.0, 0.0, uniforms.time + 5.0)

    var cv = ro + Vec3(0.0, 0.0, 4.0)
    var rd = calc_cam(q, ro, cv, 0.4)
    var t = trace[map, far=far](ro, rd, uniforms)
    var p = ro + rd * t
    var n = calc_normal[map](p, uniforms)
    if t > far:
        return Vec3(0.0, 0.0, 0.0)
    comptime lp = Vec3(0.0, 0.5, 0.0)
    var ld = (lp - p).normalize()
    var diff = n.dot(ld) * 0.5 + 0.5
    diff *= diff
    var color = Vec3(diff, diff, diff)
    color = mix(color, Vec3(0.0, 0.0, 0.0), t / far)

    return color


fn texture_kernel[
    texture_origin: MutOrigin
](texture_data: Span[UInt8, texture_origin], uniforms: Uniforms,):
    var idx = Int(global_idx.x)
    if idx >= uniforms.width * uniforms.height:
        return

    var x = idx % uniforms.width
    var y = idx // uniforms.width

    var u = Float32(x) / Float32(uniforms.width)
    var v = Float32(y) / Float32(uniforms.height)
    var col = main_image({u, v}, uniforms)

    var r = UInt8(col.x * 255.0)
    var g = UInt8(col.y * 255.0)
    var b = UInt8(col.z * 255.0)
    var a = UInt8(255)

    var pixel_idx = idx * 4
    texture_data[pixel_idx + 0] = r
    texture_data[pixel_idx + 1] = g
    texture_data[pixel_idx + 2] = b
    texture_data[pixel_idx + 3] = a


fn update(ctx: Context, mut model: Model, var update: Update) raises:
    model.uniforms.time = ctx.time
    var buf: InlineArray[Uniforms, 1] = [model.uniforms.copy()]
    ctx.window.queue[].write_buffer(
        model.uniform_buffer,
        0,
        Span[UInt8, origin_of(buf)](
            ptr=buf.unsafe_ptr().bitcast[UInt8](),
            length=len(buf) * sys.size_of[Uniforms](),
        ),
    )

    var width = Int(ctx.window.surface_conf.width)
    var height = Int(ctx.window.surface_conf.height)

    comptime uv_kernel = texture_kernel[origin_of(model.texture_data)]
    model.device_ctx.enqueue_function_checked[uv_kernel, uv_kernel](
        Span[UInt8, origin_of(model.texture_data)](
            ptr=UnsafePointer(
                model.texture_data.unsafe_ptr()
            ).unsafe_origin_cast[origin_of(model.texture_data)](),
            length=len(model.texture_data),
        ),
        model.uniforms,
        grid_dim=width * height,
        block_dim=1,
    )

    with model.texture_data.map_to_host() as texture_host:
        ctx.window.queue[].write_texture(
            wgpu.ImageCopyTexture(
                texture=model.texture,
                mip_level=0,
                origin=wgpu.Origin3D(x=0, y=0, z=0),
                aspect=wgpu.TextureAspect.all,
            ),
            Span[UInt8, origin_of(texture_host)](
                ptr=UnsafePointer[UInt8, origin_of(texture_host)](
                    texture_host.unsafe_ptr()
                ),
                length=len(texture_host),
            ),
            wgpu.TextureDataLayout(
                offset=0,
                bytes_per_row=UInt32(width * 4),
                rows_per_image=UInt32(height),
            ),
            wgpu.Extent3D(
                width=UInt32(width),
                height=UInt32(height),
                depth_or_array_layers=1,
            ),
        )


fn event(ctx: Context, mut model: Model, var event: Event) raises:
    if event.is_window_event() and event.get_window_event().is_resized():
        var wh = event.get_window_event().get_resized().value

        model.uniforms.width = Int(wh.x)
        model.uniforms.height = Int(wh.y)

        model.texture = ctx.window.device[].create_texture(
            wgpu.TextureDescriptor(
                label="fullscreen texture",
                size=wgpu.Extent3D(
                    width=ctx.window.surface_conf.width,
                    height=ctx.window.surface_conf.height,
                    depth_or_array_layers=1,
                ),
                mip_level_count=1,
                sample_count=1,
                dimension=wgpu.TextureDimension.d2,
                format=wgpu.TextureFormat.rgba8_unorm,
                usage=wgpu.TextureUsage.texture_binding
                | wgpu.TextureUsage.copy_dst
                | wgpu.TextureUsage.render_attachment,
                view_formats=List[wgpu.TextureFormat](),
            )
        )
        model.texture_view = model.texture.create_view(
            wgpu.TextureViewDescriptor(
                label="fullscreen texture view",
                format=wgpu.TextureFormat.rgba8_unorm,
                dimension=wgpu.TextureViewDimension.d2,
                aspect=wgpu.TextureAspect.all,
                base_mip_level=0,
                mip_level_count=1,
                base_array_layer=0,
                array_layer_count=1,
            )
        )
        model.texture_data = model.device_ctx.enqueue_create_buffer[
            DType.uint8
        ](Int(wh.x) * Int(wh.y) * 4)

        comptime uniform_bind_group_origin = origin_of(
            model.texture_view, model.uniform_buffer, model.texture_sampler
        )
        uniform_bind_group_entries = [
            wgpu.BindGroupEntry[uniform_bind_group_origin](
                0,
                wgpu.BufferBinding[uniform_bind_group_origin](
                    model.uniform_buffer, 0, sys.size_of[Uniforms]()
                ),
            ),
            wgpu.BindGroupEntry[uniform_bind_group_origin](
                1, model.texture_view
            ),
            wgpu.BindGroupEntry[uniform_bind_group_origin](
                2, model.texture_sampler
            ),
        ]

        var bind_group_entries = [
            wgpu.BindGroupLayoutEntry(
                binding=0,
                visibility=wgpu.ShaderStage.fragment | wgpu.ShaderStage.vertex,
                type=wgpu.BufferBindingLayout(
                    type=wgpu.BufferBindingType.uniform,
                    has_dynamic_offset=True,
                    min_binding_size=sys.size_of[Uniforms](),
                ),
                count=0,
            ),
            wgpu.BindGroupLayoutEntry(
                binding=1,
                visibility=wgpu.ShaderStage.fragment,
                type=wgpu.TextureBindingLayout(
                    sample_type=wgpu.TextureSampleType.float,
                    view_dimension=wgpu.TextureViewDimension.d2,
                    multisampled=False,
                ),
                count=0,
            ),
            wgpu.BindGroupLayoutEntry(
                binding=2,
                visibility=wgpu.ShaderStage.fragment,
                type=wgpu.SamplerBindingLayout(
                    type=wgpu.SamplerBindingType.filtering,
                ),
                count=0,
            ),
        ]
        var bind_group_layout = ArcPointer(
            ctx.window.device[].create_bind_group_layout(
                {
                    "bind group layout",
                    bind_group_entries,
                }
            )
        )

        model.uniform_bind_group = ctx.window.device[].create_bind_group(
            {
                "bind group",
                bind_group_layout,
                uniform_bind_group_entries,
            }
        )


fn view(ctx: Context, model: Model, var frame: Frame) raises:
    ref encoder = frame.command_encoder()
    var color_attachments = [
        ArcPointer(
            wgpu.RenderPassColorAttachment[ImmutAnyOrigin](
                view=frame.texture_view()[],
                load_op=wgpu.LoadOp.clear,
                store_op=wgpu.StoreOp.store,
                clear_value=wgpu.Color(0.9, 0.1, 0.2, 1.0),
            )
        )
    ]

    var rp = encoder.begin_render_pass({color_attachments = color_attachments^})
    rp.set_pipeline(model.render_pipeline)
    rp.set_vertex_buffer(0, 0, model.vertex_buffer.size(), model.vertex_buffer)
    rp.set_index_buffer(
        model.index_buffer,
        wgpu.IndexFormat.uint32,
        0,
        model.index_buffer.size(),
    )
    rp.set_bind_group(0, model.uniform_bind_group, List[UInt32](0))
    rp.draw_indexed(model.num_indices, 1, 0, 0, 0)

    frame^.submit()


fn main() raises:
    var app = App[model, update_fn=update, event_fn=event, view_fn=view]()
    app^.run()
