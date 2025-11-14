import wgpu
from shimmer import App, Context, Update, Event, Frame
from shimmer.geom import Vec3, Mat4, Camera

from gpu.host import DeviceContext, DeviceBuffer
from gpu import global_idx
from hashlib.hasher import Hasher
import math
from memory import ArcPointer, memcpy
from random import random_float64, random_ui64
import sys


fn smoothstep(edge0: Float32, edge1: Float32, x: Float32) -> Float32:
    var t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


fn mix(x: Float32, y: Float32, a: Float32) -> Float32:
    return x * (1.0 - a) + y * a


fn mix(x: Vec3, y: Vec3, a: Float32) -> Vec3:
    return {
        mix(x.x, y.x, a),
        mix(x.y, y.y, a),
        mix(x.z, y.z, a),
    }


fn poisson_sphere_sampling_fast[
    k: Int = 30
](
    min_distance: Float32,
    radius: Float32 = 1.0,
    max_points: Optional[Int] = None,
) -> List[Vec3]:
    points: List[Vec3] = []
    active_list: List[Vec3] = []

    fn random_sphere_point() -> Vec3:
        u = Float32(random_float64(0, 1))
        v = Float32(random_float64(0, 1))
        theta = 2 * math.pi * u
        phi = math.acos(2 * v - 1)
        x = radius * math.sin(phi) * math.cos(theta)
        y = radius * math.sin(phi) * math.sin(theta)
        z = radius * math.cos(phi)
        return Vec3(x, y, z)

    fn spherical_distance(p1: Vec3, p2: Vec3) -> Float32:
        p1_norm = p1 / p1.length()
        p2_norm = p2 / p2.length()
        dot = math.clamp(p1_norm.dot(p2_norm), -1.0, 1.0)
        return math.acos(dot) * radius

    fn random_point_around(
        center: Vec3, min_dist: Float32, max_dist: Float32
    ) -> Optional[Vec3]:
        for _ in range(100):
            point = random_sphere_point()
            dist = spherical_distance(center, point)
            if min_dist <= dist <= max_dist:
                return point
        return None

    fn is_valid(
        point: Vec3,
    ) unified {
        read points, read radius, read min_distance, read spherical_distance
    } -> Bool:
        # Check distance to all existing points
        for existing_point in points:
            dist = spherical_distance(point, existing_point)
            if dist < min_distance:
                return False
        return True

    # Initialize
    initial = random_sphere_point()
    points.append(initial)
    active_list.append(initial)

    # Main loop
    while len(active_list) > 0:
        if max_points and len(points) >= max_points.value():
            break

        idx = random_ui64(0, len(active_list))
        center = active_list[idx]

        found = False
        for _ in range(k):
            new_point = random_point_around(
                center, min_distance, 2 * min_distance
            )
            if new_point is not None and is_valid(new_point.value()):
                points.append(new_point.value())
                active_list.append(new_point.value())
                found = True
                break

        if not found:
            _ = active_list.pop(Int(idx))

    return points^


fn create_icosahedron() -> Tuple[List[Vec3], List[UInt32]]:
    """
    Create an icosahedron with vertices and faces.
    Returns vertices (12x3 array) and faces (20x3 array of vertex indices).
    """
    var phi = Float32(1 + math.sqrt(5)) / 2

    var vertices: List[Vec3] = [
        {-1, phi, 0},
        {1, phi, 0},
        {-1, -phi, 0},
        {1, -phi, 0},
        {0, -1, phi},
        {0, 1, phi},
        {0, -1, -phi},
        {0, 1, -phi},
        {phi, 0, -1},
        {phi, 0, 1},
        {-phi, 0, -1},
        {-phi, 0, 1},
    ]

    for ref vertex in vertices:
        vertex /= vertex.length()

    # Standard icosahedron faces with consistent CCW winding
    var faces: List[UInt32] = [
        # fmt: off
        # 5 faces around point 0
        0, 11, 5,
        0, 5, 1,
        0, 1, 7,
        0, 7, 10,
        0, 10, 11,
        # 5 adjacent faces
        1, 5, 9,
        5, 11, 4,
        11, 10, 2,
        10, 7, 6,
        7, 1, 8,
        # 5 faces around point 3
        3, 9, 4,
        3, 4, 2,
        3, 2, 6,
        3, 6, 8,
        3, 8, 9,
        # 5 adjacent faces
        4, 9, 5,
        2, 4, 11,
        6, 2, 10,
        8, 6, 7,
        9, 8, 1,
        # fmt: on
    ]

    # Ensure all faces have correct winding (outward normals)
    var flipped = 0
    for i in range(0, len(faces), 3):
        var v0 = vertices[Int(faces[i])]
        var v1 = vertices[Int(faces[i + 1])]
        var v2 = vertices[Int(faces[i + 2])]

        # Compute face normal using cross product
        var edge1 = v1 - v0
        var edge2 = v2 - v0
        var normal = edge1.cross(edge2)

        # Face center (average of vertices)
        var center = (v0 + v1 + v2) / 3

        # For a sphere, normal should point in same direction as center (outward from origin)
        # If dot product is negative, they point in opposite directions - flip it
        if normal.dot(center) < 0:
            var temp = faces[i + 1]
            faces[i + 1] = faces[i + 2]
            faces[i + 2] = temp
            flipped += 1

    return vertices^, faces^


@fieldwise_init
struct Pair(
    Copyable, EqualityComparable, Hashable, ImplicitlyCopyable, Movable
):
    var first: UInt32
    var second: UInt32

    fn __hash__[H: Hasher](self, mut hasher: H):
        hasher.update(self.first)
        hasher.update(self.second)

    fn __eq__(self, rhs: Self) -> Bool:
        return self.first == rhs.first and self.second == rhs.second


fn subdivide[
    resolution: Int = 1
](var vf: Tuple[List[Vec3], List[UInt32]]) -> Tuple[List[Vec3], List[UInt32]]:
    """
    Subdivide each triangular face into smaller triangles.

    Parameters:
        resolution: Number of subdivision iterations (0 = original, 1 = 4x faces, 2 = 16x faces, etc.).

    Args:
        vf: A tuple containing vertices and faces

    Returns:
        A tuple containing `new_vertices, new_faces`.
    """
    if resolution == 0:
        return vf^

    @parameter
    for _ in range(resolution):
        var new_faces: List[UInt32] = []
        var edge_midpoints: Dict[Pair, Int] = {}
        var vertex_list = vf[0].copy()

        fn get_midpoint(
            v1_idx: UInt32, v2_idx: UInt32
        ) unified {mut edge_midpoints, mut vertex_list} -> UInt32:
            """Get or create midpoint between two vertices."""
            var edge: Pair
            if v1_idx < v2_idx:
                edge = Pair(v1_idx, v2_idx)
            else:
                edge = Pair(v2_idx, v1_idx)

            if edge not in edge_midpoints:
                # Calculate midpoint
                var midpoint = (
                    vertex_list[Int(v1_idx)] + vertex_list[Int(v2_idx)]
                ) / 2
                # Project onto unit sphere
                midpoint = midpoint / midpoint.length()
                # Add to vertex list
                vertex_list.append(midpoint)
                edge_midpoints[edge] = len(vertex_list) - 1

            try:
                return UInt32(edge_midpoints[edge])
            except:
                return 0

        # Subdivide each face into 4 smaller triangles
        # for face in faces:
        for i in range(0, len(vf[1]), 3):
            var v0 = vf[1][i + 0]
            var v1 = vf[1][i + 1]
            var v2 = vf[1][i + 2]

            var m01 = get_midpoint(v0, v1)
            var m12 = get_midpoint(v1, v2)
            var m20 = get_midpoint(v2, v0)

            new_faces.reserve(len(new_faces) + 12)
            # Corner triangle at v0
            new_faces.append(v0)
            new_faces.append(m01)
            new_faces.append(m20)

            # Corner triangle at v1
            new_faces.append(v1)
            new_faces.append(m12)
            new_faces.append(m01)

            # Corner triangle at v2
            new_faces.append(v2)
            new_faces.append(m20)
            new_faces.append(m12)

            # Center triangle
            new_faces.append(m01)
            new_faces.append(m12)
            new_faces.append(m20)

        vf[0] = vertex_list^
        vf[1] = new_faces^

    for i in range(0, len(vf[1]), 3):
        var v0 = vf[0][Int(vf[1][i])]
        var v1 = vf[0][Int(vf[1][i + 1])]
        var v2 = vf[0][Int(vf[1][i + 2])]

        var edge1 = v1 - v0
        var edge2 = v2 - v0
        var normal = edge1.cross(edge2)
        var center = (v0 + v1 + v2) / 3

    return vf^


@fieldwise_init
struct Uniforms(Copyable, Movable):
    var view_proj: InlineArray[InlineArray[Float32, 4], 4]
    var time: Float32

    fn update_view_proj(mut self, camera: Camera):
        self.view_proj = (
            camera.build_view_projection_matrix().to_cols_array_2d()
        )


@fieldwise_init
struct Model(Movable):
    var device_ctx: DeviceContext
    var render_pipeline: wgpu.RenderPipeline
    var vertices: DeviceBuffer[DType.float32]
    var scratch: DeviceBuffer[DType.float32]
    var normals: DeviceBuffer[DType.float32]
    var random_offsets: DeviceBuffer[DType.float32]
    var random_offsets_original: DeviceBuffer[DType.float32]
    var colors: DeviceBuffer[DType.float32]
    var smoothed_colors: DeviceBuffer[DType.float32]
    var indices: DeviceBuffer[DType.uint32]
    var vertex_buffer: wgpu.Buffer[Float32]
    var normal_buffer: wgpu.Buffer[Float32]
    var color_buffer: wgpu.Buffer[Float32]
    var index_buffer: wgpu.Buffer[UInt32]
    var num_indices: Int
    var camera: Camera
    var uniform_bind_group: wgpu.BindGroup
    var uniform_buffer: wgpu.Buffer[Uniforms]
    var uniforms: Uniforms
    var random_step: List[Float32]


fn model(ctx: Context) raises -> Model:
    try:
        with DeviceContext() as device_ctx:
            # The gpu device associated with the window's swapchain
            # let window = app.window(w_id).unwrap();
            var device = ctx.window.device
            # var format = Frame.TEXTURE_FORMAT
            # let sample_count = window.msaa_samples();

            var vf = subdivide[4](create_icosahedron())

            # Load shader modules.
            var fs_desc = """
            struct VertexOutput {
                @builtin(position) clip_position: vec4<f32>,
                @location(0) world_normal: vec3<f32>,
                @location(1) world_position: vec3<f32>,
                @location(2) vertex_color: vec3<f32>,
            }

            @fragment
            fn main(in: VertexOutput) -> @location(0) vec4<f32> {
                let normal = normalize(in.world_normal);
                let light_dir = normalize(vec3<f32>(1.5, 1.8, 1.6));
                let view_dir = normalize(vec3<f32>(0.0, 5.0, 2.0) - in.world_position);

                // Harsher diffuse lighting with more contrast
                let diffuse_raw = max(dot(normal, light_dir), 0.0);
                let diffuse = pow(diffuse_raw, 2.0);  // Sharpen the falloff

                // Specular lighting (Blinn-Phong) - increased for more highlights
                let half_dir = normalize(light_dir + view_dir);
                let specular_strength = 0.8;
                let shininess = 64.0;  // Higher shininess for sharper highlights
                let specular = specular_strength * pow(max(dot(normal, half_dir), 0.0), shininess);

                // Lower ambient for more contrast
                let ambient = 0.1;

                let color = in.vertex_color;
                let final_color = color * (ambient + diffuse * 1.2) + vec3<f32>(specular);
                return vec4<f32>(final_color, 1.0);
            }"""
            var vs_desc = """
            struct Uniforms {
                view_proj: mat4x4<f32>,
            }

            @group(0) @binding(0)
            var<uniform> uniforms: Uniforms;

            struct VertexInput {
                @location(0) position: vec3<f32>,
                @location(1) normal: vec3<f32>,
                @location(2) vertex_color: vec3<f32>,
            }

            struct VertexOutput {
                @builtin(position) clip_position: vec4<f32>,
                @location(0) world_normal: vec3<f32>,
                @location(1) world_position: vec3<f32>,
                @location(2) vertex_color: vec3<f32>,
            }

            @vertex
            fn main(model: VertexInput) -> VertexOutput {
                var out: VertexOutput;
                out.clip_position = uniforms.view_proj * vec4<f32>(model.position, 1.0);
                // Use the pre-computed normal from the vertex buffer
                out.world_normal = model.normal;
                out.world_position = model.position;
                out.vertex_color = model.vertex_color;
                return out;
            }
            """
            var fs_mod = device[].create_wgsl_shader_module(code=fs_desc)
            var vs_mod = device[].create_wgsl_shader_module(code=vs_desc)

            # Create the vertex buffer.
            var vertex_usage = (
                wgpu.BufferUsage.vertex | wgpu.BufferUsage.copy_dst
            )
            var vertex_buffer = device[].create_buffer[Float32](
                {
                    label = "vertex buffer",
                    size = len(vf[0]) * 3,
                    usage = vertex_usage,
                    mapped_at_creation = True,
                }
            )
            with vertex_buffer.get_mapped_range(
                0, len(vf[0]) * 3
            ) as vertex_host:
                for i in range(len(vf[0])):
                    vertex_host[i * 3 + 0] = vf[0][i].x
                    vertex_host[i * 3 + 1] = vf[0][i].y
                    vertex_host[i * 3 + 2] = vf[0][i].z

            # Create the normal buffer (for a unit sphere, normals = positions)
            var normal_buffer = device[].create_buffer[Float32](
                {
                    label = "normal buffer",
                    size = len(vf[0]) * 3,
                    usage = vertex_usage,
                    mapped_at_creation = True,
                }
            )
            with normal_buffer.get_mapped_range(
                0, len(vf[0]) * 3
            ) as normal_host:
                for i in range(len(vf[0])):
                    # For a unit sphere, the normal at each vertex is the normalized position
                    var normal = vf[0][i].normalize()
                    normal_host[i * 3 + 0] = normal.x
                    normal_host[i * 3 + 1] = normal.y
                    normal_host[i * 3 + 2] = normal.z

            # Create the color buffer
            var color_buffer = device[].create_buffer[Float32](
                {
                    label = "color buffer",
                    size = len(vf[0]) * 3,
                    usage = vertex_usage,
                    mapped_at_creation = True,
                }
            )
            with color_buffer.get_mapped_range(0, len(vf[0]) * 3) as color_host:
                for i in range(len(vf[0])):
                    # Set colors (you can customize this)
                    color_host[i * 3 + 0] = 0.8  # R
                    color_host[i * 3 + 1] = 0.3  # G
                    color_host[i * 3 + 2] = 0.4  # B

            var vertex_attributes = [
                wgpu.VertexAttribute(
                    format=wgpu.VertexFormat.float32x3,
                    offset=0,
                    shader_location=0,
                )
            ]

            var normal_attributes = [
                wgpu.VertexAttribute(
                    format=wgpu.VertexFormat.float32x3,
                    offset=0,
                    shader_location=1,
                )
            ]

            var color_attributes = [
                wgpu.VertexAttribute(
                    format=wgpu.VertexFormat.float32x3,
                    offset=0,
                    shader_location=2,
                )
            ]

            alias vbl_origin = ImmutOrigin.cast_from[
                origin_of(
                    vertex_attributes, normal_attributes, color_attributes
                )
            ]
            var vertex_buffer_layouts = [
                wgpu.VertexBufferLayout(
                    array_stride=sys.size_of[Float32]() * 3,
                    step_mode=wgpu.VertexStepMode.vertex,
                    attributes=vertex_attributes^,
                ),
                wgpu.VertexBufferLayout(
                    array_stride=sys.size_of[Float32]() * 3,
                    step_mode=wgpu.VertexStepMode.vertex,
                    attributes=normal_attributes^,
                ),
                wgpu.VertexBufferLayout(
                    array_stride=sys.size_of[Float32]() * 3,
                    step_mode=wgpu.VertexStepMode.vertex,
                    attributes=color_attributes^,
                ),
            ]

            var index_usage = wgpu.BufferUsage.index | wgpu.BufferUsage.copy_dst
            var index_buffer = device[].create_buffer[UInt32](
                {
                    label = "index buffer",
                    size = len(vf[1]),
                    usage = index_usage,
                    mapped_at_creation = True,
                }
            )
            with index_buffer.get_mapped_range(0, len(vf[1])) as index_host:
                for i in range(len(vf[1])):
                    index_host[i] = vf[1][i]

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
                )
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
                        cull_mode=wgpu.CullMode.back,
                    ),
                    multisample = wgpu.MultisampleState(),
                    layout = Pointer(to=pipeline_layout).get_immutable(),
                    depth_stencil = None,
                }
            )

            var vertices = device_ctx.enqueue_create_buffer[DType.float32](
                len(vf[0]) * 3
            )
            var scratch = device_ctx.enqueue_create_buffer[DType.float32](
                len(vf[0]) * 3
            )
            var normals = device_ctx.enqueue_create_buffer[DType.float32](
                len(vf[0]) * 3
            )
            var colors = device_ctx.enqueue_create_buffer[DType.float32](
                len(vf[0]) * 3
            )
            var smoothed_colors = device_ctx.enqueue_create_buffer[
                DType.float32
            ](len(vf[0]) * 3)
            var indices = device_ctx.enqueue_create_buffer[DType.uint32](
                len(vf[1])
            )
            var sampled_points = poisson_sphere_sampling_fast(
                1.0, max_points=100
            )
            var random_offsets = device_ctx.enqueue_create_buffer[
                DType.float32
            ](len(sampled_points) * 3)
            var random_offsets_original = device_ctx.enqueue_create_buffer[
                DType.float32
            ](len(sampled_points) * 3)

            var random_step = [
                Float32(random_float64(0.0, 2.0 * math.pi))
                for _ in range(len(sampled_points))
            ]

            with vertices.map_to_host() as v_host:
                for i in range(len(vf[0])):
                    v_host[i * 3 + 0] = vf[0][i].x
                    v_host[i * 3 + 1] = vf[0][i].y
                    v_host[i * 3 + 2] = vf[0][i].z

            with normals.map_to_host() as n_host:
                for i in range(len(vf[0])):
                    var normal = vf[0][i].normalize()
                    n_host[i * 3 + 0] = normal.x
                    n_host[i * 3 + 1] = normal.y
                    n_host[i * 3 + 2] = normal.z

            with colors.map_to_host() as c_host:
                for i in range(len(vf[0])):
                    c_host[i * 3 + 0] = 0.8  # R
                    c_host[i * 3 + 1] = 0.3  # G
                    c_host[i * 3 + 2] = 0.4  # B

            with indices.map_to_host() as i_host:
                for i in range(len(vf[1])):
                    i_host[i] = vf[1][i]

            with random_offsets.map_to_host() as r_host:
                for i in range(len(random_offsets) // 3):
                    r_host[i * 3 + 0] = sampled_points[i].x
                    r_host[i * 3 + 1] = sampled_points[i].y
                    r_host[i * 3 + 2] = sampled_points[i].z

            with random_offsets_original.map_to_host() as r_orig_host:
                for i in range(len(random_offsets_original) // 3):
                    r_orig_host[i * 3 + 0] = sampled_points[i].x
                    r_orig_host[i * 3 + 1] = sampled_points[i].y
                    r_orig_host[i * 3 + 2] = sampled_points[i].z

            var uniform_buffer = device[].create_buffer[Uniforms](
                {
                    "uniform buffer",
                    wgpu.BufferUsage.uniform | wgpu.BufferUsage.copy_dst,
                    sys.size_of[Uniforms](),
                    True,
                }
            )
            var uniforms = Uniforms(
                time=0, view_proj=Mat4.IDENTITY.to_cols_array_2d()
            )
            with uniform_buffer.get_mapped_range(0, 1) as uniform_host:
                uniform_host[0] = uniforms.copy()

            uniform_bind_group_entries = [
                wgpu.BindGroupEntry[Uniforms](
                    0,
                    wgpu.BufferBinding[Uniforms](
                        uniform_buffer, 0, sys.size_of[Uniforms]()
                    ),
                )
            ]
            uniform_bind_group = device[].create_bind_group(
                {
                    "bind group",
                    bind_group_layouts[0],
                    uniform_bind_group_entries,
                }
            )
            var camera = Camera(
                eye={0.0, 5.0, 2.0},
                target={0.0, 0.0, 0.0},
                up=Vec3.Y,
                aspect=Float32(ctx.window.surface_conf.width)
                / Float32(ctx.window.surface_conf.height),
                fovy=45.0,
                znear=0.1,
                zfar=100.0,
            )

            return Model(
                device_ctx=device_ctx,
                vertex_buffer=vertex_buffer^,
                index_buffer=index_buffer^,
                render_pipeline=pipeline^,
                vertices=vertices,
                num_indices=len(vf[1]),
                camera=camera^,
                uniform_bind_group=uniform_bind_group^,
                uniform_buffer=uniform_buffer^,
                uniforms=uniforms^,
                scratch=scratch^,
                normals=normals^,
                normal_buffer=normal_buffer^,
                color_buffer=color_buffer^,
                colors=colors^,
                smoothed_colors=smoothed_colors^,
                indices=indices^,
                random_offsets=random_offsets^,
                random_offsets_original=random_offsets_original^,
                random_step=random_step^,
            )
    except:
        print("failed to create device context")
        while True:
            pass


fn kernel[
    verts_origin: ImmutOrigin,
    offset_origin: ImmutOrigin,
    out_origin: MutOrigin,
    colors_origin: MutOrigin,
](
    verts: Span[Float32, verts_origin],
    offsets: Span[Float32, offset_origin],
    output: Span[Float32, out_origin],
    colors: Span[Float32, colors_origin],
    time: Float32,
):
    if Int(global_idx.x) >= len(verts) // 3:
        return

    var pos = Vec3(
        verts[global_idx.x * 3 + 0],
        verts[global_idx.x * 3 + 1],
        verts[global_idx.x * 3 + 2],
    )

    var min_dist = Float32.MAX
    for i in range(len(offsets)):
        pt = Vec3(
            offsets[i * 3 + 0],
            offsets[i * 3 + 1],
            offsets[i * 3 + 2],
        )
        min_dist = min(min_dist, (pos - pt).length())

    colors[global_idx.x * 3 + 0] = min_dist
    colors[global_idx.x * 3 + 1] = min_dist
    colors[global_idx.x * 3 + 2] = min_dist

    output[global_idx.x * 3 + 0] = pos.x
    output[global_idx.x * 3 + 1] = pos.y
    output[global_idx.x * 3 + 2] = pos.z


fn smooth_colors_kernel[
    colors_origin: ImmutOrigin,
    indices_origin: ImmutOrigin,
    smoothed_origin: MutOrigin,
](
    colors: Span[Float32, colors_origin],
    indices: Span[UInt32, indices_origin],
    smoothed: Span[Float32, smoothed_origin],
):
    var vertex_idx = Int(global_idx.x)
    if vertex_idx >= len(colors) // 3:
        return

    var sum = colors[vertex_idx * 3]
    var count = 1

    # Find neighboring vertices by looking at triangles
    for i in range(0, len(indices), 3):
        var i0 = Int(indices[i + 0])
        var i1 = Int(indices[i + 1])
        var i2 = Int(indices[i + 2])

        # If this triangle contains our vertex, add its other vertices
        if i0 == vertex_idx:
            sum += colors[i1 * 3]
            sum += colors[i2 * 3]
            count += 2
        elif i1 == vertex_idx:
            sum += colors[i0 * 3]
            sum += colors[i2 * 3]
            count += 2
        elif i2 == vertex_idx:
            sum += colors[i0 * 3]
            sum += colors[i1 * 3]
            count += 2

    # Average the color values
    var smoothed_color = sum / Float32(count)
    smoothed[vertex_idx * 3 + 0] = smoothed_color
    smoothed[vertex_idx * 3 + 1] = smoothed_color
    smoothed[vertex_idx * 3 + 2] = smoothed_color


fn kernel2[
    pos_origin: MutOrigin,
    colors_origin: MutOrigin,
](
    positions: Span[Float32, pos_origin],
    colors: Span[Float32, colors_origin],
    max_dist: Float32,
    time: Float32,
):
    if Int(global_idx.x) >= len(colors) // 3:
        return

    # Avoid division by zero
    var safe_max_dist = max(max_dist, 0.0001)
    colors[global_idx.x * 3 + 0] /= safe_max_dist
    colors[global_idx.x * 3 + 1] /= safe_max_dist
    colors[global_idx.x * 3 + 2] /= safe_max_dist

    var t = colors[global_idx.x * 3]  # Clamp to [0, 1]

    # Multi-point gradient using mix
    if t < 0.1:
        color = mix(2.0, 0.424, t / 0.1)
    elif t < 0.2:
        color = mix(0.424, 0.627, (t - 0.1) / 0.1)
    elif t < 0.4:
        color = mix(0.627, 0.599, (t - 0.2) / 0.2)
    elif t < 0.45:
        color = mix(0.599, 0.474, (t - 0.4) / 0.05)
    else:
        color = mix(0.474, 0.598, (t - 0.45) / 0.55)

    # Override to verify the function ran
    if global_idx.x == 0:
        color = 1.0  # Should make one vertex bright white
    colors[global_idx.x * 3 + 0] = color
    colors[global_idx.x * 3 + 1] = color
    colors[global_idx.x * 3 + 2] = color

    var pos = Vec3(
        positions[global_idx.x * 3 + 0],
        positions[global_idx.x * 3 + 1],
        positions[global_idx.x * 3 + 2],
    )
    # Displacement based on color/distance values
    var displacement = colors[global_idx.x * 3]
    var scaled_pos = pos + pos * displacement
    positions[global_idx.x * 3 + 0] = scaled_pos.x
    positions[global_idx.x * 3 + 1] = scaled_pos.y
    positions[global_idx.x * 3 + 2] = scaled_pos.z


fn compute_normals_kernel[
    pos_origin: ImmutOrigin,
    normals_origin: MutOrigin,
    indices_origin: ImmutOrigin,
](
    positions: Span[Float32, pos_origin],
    normals: Span[Float32, normals_origin],
    indices: Span[UInt32, indices_origin],
):
    var vertex_idx = Int(global_idx.x)
    if vertex_idx >= len(positions) // 3:
        return

    var normal_sum = Vec3(0.0, 0.0, 0.0)
    var tri_count = 0

    # Find all triangles containing this vertex and average their normals
    for i in range(0, len(indices), 3):
        var i0 = Int(indices[i + 0])
        var i1 = Int(indices[i + 1])
        var i2 = Int(indices[i + 2])

        if i0 == vertex_idx or i1 == vertex_idx or i2 == vertex_idx:
            # Get the three vertices of this triangle
            var v0 = Vec3(
                positions[i0 * 3 + 0],
                positions[i0 * 3 + 1],
                positions[i0 * 3 + 2],
            )
            var v1 = Vec3(
                positions[i1 * 3 + 0],
                positions[i1 * 3 + 1],
                positions[i1 * 3 + 2],
            )
            var v2 = Vec3(
                positions[i2 * 3 + 0],
                positions[i2 * 3 + 1],
                positions[i2 * 3 + 2],
            )

            # Compute face normal
            var edge1 = v1 - v0
            var edge2 = v2 - v0
            var face_normal = edge1.cross(edge2)
            normal_sum = normal_sum + face_normal
            tri_count += 1

    # Average and normalize
    var avg_normal = normal_sum / Float32(max(tri_count, 1))
    var normal_length = avg_normal.length()

    # Fallback to position-based normal if we get a degenerate result
    var normal: Vec3
    if normal_length < 0.001:
        # Use the vertex position as fallback (works for spherical surfaces)
        var pos = Vec3(
            positions[vertex_idx * 3 + 0],
            positions[vertex_idx * 3 + 1],
            positions[vertex_idx * 3 + 2],
        )
        normal = pos.normalize()
    else:
        normal = avg_normal / normal_length

    normals[vertex_idx * 3 + 0] = normal.x
    normals[vertex_idx * 3 + 1] = normal.y
    normals[vertex_idx * 3 + 2] = normal.z


fn update(ctx: Context, mut model: Model, var update: Update) raises:
    model.uniforms.update_view_proj(model.camera)
    model.uniforms.time = ctx.time
    var buf: InlineArray[Uniforms, 1] = [model.uniforms.copy()]
    ctx.window.queue[].write_buffer(model.uniform_buffer, 0, buf)
    # Rotate from original positions each frame to avoid accumulation
    with model.random_offsets_original.map_to_host() as r_orig_host:
        with model.random_offsets.map_to_host() as r_host:
            var rot_x = Mat4.from_rotation_x(ctx.time * 0.5)
            var rot_y = Mat4.from_rotation_y(ctx.time * 0.35)
            for i in range(len(r_host) // 3):
                var pt = rot_x.transform_point3(
                    Vec3(
                        r_orig_host[i * 3 + 0],
                        r_orig_host[i * 3 + 1],
                        r_orig_host[i * 3 + 2],
                    )
                )
                pt *= 1.0 + 0.5 + 0.5 * math.sin(ctx.time)
                pt = rot_y.transform_point3(pt)
                r_host[i * 3 + 0] = pt.x * (
                    1.0 + 0.5 * math.cos(ctx.time + model.random_step[i])
                )
                r_host[i * 3 + 1] = pt.y * (
                    1.0 + 0.5 * math.cos(ctx.time + model.random_step[i])
                )
                r_host[i * 3 + 2] = pt.z * (
                    1.0 + 0.5 * math.cos(ctx.time + model.random_step[i])
                )

    alias k = kernel[
        origin_of(model.vertices),
        origin_of(model.random_offsets),
        origin_of(model.scratch),
        origin_of(model.colors),
    ]
    model.device_ctx.enqueue_function_checked[k, k](
        Span[Float32, origin_of(model.vertices)](
            ptr=UnsafePointer(model.vertices.unsafe_ptr()).unsafe_origin_cast[
                origin_of(model.vertices)
            ](),
            length=len(model.vertices),
        ).get_immutable(),
        Span[Float32, origin_of(model.random_offsets)](
            ptr=UnsafePointer(
                model.random_offsets.unsafe_ptr()
            ).unsafe_origin_cast[origin_of(model.random_offsets)](),
            length=len(model.random_offsets),
        ).get_immutable(),
        Span[Float32, origin_of(model.scratch)](
            ptr=UnsafePointer(model.scratch.unsafe_ptr()).unsafe_origin_cast[
                origin_of(model.scratch)
            ](),
            length=len(model.scratch),
        ),
        Span[Float32, origin_of(model.colors)](
            ptr=UnsafePointer(model.colors.unsafe_ptr()).unsafe_origin_cast[
                origin_of(model.colors)
            ](),
            length=len(model.colors),
        ),
        ctx.time,
        grid_dim=len(model.vertices) // 3,
        block_dim=1,
    )

    var max_dist = Float32.MIN
    with model.colors.map_to_host() as colors_host:
        for i in range(len(model.colors) // 3):
            max_dist = max(colors_host[i * 3 + 0], max_dist)

    # Ensure max_dist is never zero to avoid division by zero
    max_dist = max(max_dist, 0.0001)

    # Apply gradient and normalization directly to colors (skip smoothing for performance)
    alias k2 = kernel2[
        origin_of(model.scratch),
        origin_of(model.colors),
    ]
    model.device_ctx.enqueue_function_checked[k2, k2](
        Span[Float32, origin_of(model.scratch)](
            ptr=UnsafePointer(model.scratch.unsafe_ptr()).unsafe_origin_cast[
                origin_of(model.scratch)
            ](),
            length=len(model.scratch),
        ),
        Span[Float32, origin_of(model.colors)](
            ptr=UnsafePointer(model.colors.unsafe_ptr()).unsafe_origin_cast[
                origin_of(model.colors)
            ](),
            length=len(model.colors),
        ),
        max_dist,
        ctx.time,
        grid_dim=len(model.vertices) // 3,
        block_dim=1,
    )

    # Compute normals from displaced geometry
    alias k_normals = compute_normals_kernel[
        origin_of(model.scratch),
        origin_of(model.normals),
        origin_of(model.indices),
    ]
    model.device_ctx.enqueue_function_checked[k_normals, k_normals](
        Span[Float32, origin_of(model.scratch)](
            ptr=UnsafePointer(model.scratch.unsafe_ptr()).unsafe_origin_cast[
                origin_of(model.scratch)
            ](),
            length=len(model.scratch),
        ).get_immutable(),
        Span[Float32, origin_of(model.normals)](
            ptr=UnsafePointer(model.normals.unsafe_ptr()).unsafe_origin_cast[
                origin_of(model.normals)
            ](),
            length=len(model.normals),
        ),
        Span[UInt32, origin_of(model.indices)](
            ptr=UnsafePointer(model.indices.unsafe_ptr()).unsafe_origin_cast[
                origin_of(model.indices)
            ](),
            length=len(model.indices),
        ).get_immutable(),
        grid_dim=len(model.vertices) // 3,
        block_dim=1,
    )

    with model.colors.map_to_host() as colors_host:
        ctx.window.queue[].write_buffer(
            model.color_buffer,
            0,
            colors_host.as_span(),
        )

    with model.scratch.map_to_host() as vertex_host:
        ctx.window.queue[].write_buffer(
            model.vertex_buffer,
            0,
            vertex_host.as_span(),
        )

    with model.normals.map_to_host() as normals_host:
        ctx.window.queue[].write_buffer(
            model.normal_buffer,
            0,
            normals_host.as_span(),
        )


fn event(ctx: Context, mut model: Model, var event: Event) raises:
    if event.is_window_event() and event.get_window_event().is_resized():
        print(event)


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
    rp.set_vertex_buffer(1, 0, model.normal_buffer.size(), model.normal_buffer)
    rp.set_vertex_buffer(2, 0, model.color_buffer.size(), model.color_buffer)
    rp.set_index_buffer(
        model.index_buffer,
        wgpu.IndexFormat.uint32,
        0,
        model.index_buffer.size(),
    )
    rp.set_bind_group(0, model.uniform_bind_group, List[UInt32](0))
    rp.draw_indexed(model.num_indices, 1, 0, 0, 0)
    rp^.end()

    frame^.submit()


fn main() raises:
    var app = App[model, update_fn=update, event_fn=event, view_fn=view]()
    app^.run()
