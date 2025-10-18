fn palette(t: Float32, a: Vec3, b: Vec3, c: Vec3, d: Vec3) -> Vec3:
    return a + b * (
        Vec3(1.0, 1.0, 1.0) * (2.0 * 3.14159265 * (c * t + d)).cos()
    )


@always_inline
fn map(var p: Vec3, uniforms: Uniforms) -> Float32:
    return (
        (p.abs() + p.abs().sin() + uniforms.time).cos().length()
        - 0.5
        - uniforms.audio.y * 0.5
    )


struct Otherworldly(Shader):
    @always_inline
    @staticmethod
    fn main_image[far: Float32 = 20.0](uv: Vec2, uniforms: Uniforms) -> Vec3:
        var q = uv * 2.0 - 1.0
        (UnsafePointer(to=q).bitcast[Float32]())[] *= Float32(
            uniforms.width
        ) / Float32(uniforms.height)
        var ro = Vec3(0.0, 0.0, uniforms.time + 5.0)
        r = rot2d({ro.x, ro.z}, uniforms.time * 0.1)
        ro = Vec3(r.x, ro.y, r.y)
        r = rot2d({ro.y, ro.z}, uniforms.time * 0.1)
        ro = Vec3(ro.x, r.x, r.y)

        var cv = ro + Vec3(0.0, 0.0, 4.0)
        var rd = calc_cam(q, ro, cv, 0.4)
        var t = trace[map, far=far](ro, rd, uniforms)
        var p = ro + rd * t
        var n = calc_normal[map](p, uniforms)
        if t > far:
            return Vec3(0.0, 0.0, 0.0)
        alias lp = Vec3(0.0, 0.5, 0.0)
        var ld = (lp - p).normalize()
        var diff = n.dot(ld) * 0.5 + 0.5
        diff *= diff
        var color = palette(
            diff,
            Vec3(0.5, 0.5, 0.5),
            Vec3(0.5, 0.5, 0.5),
            Vec3(1.0, 1.0, 1.0),
            Vec3(0.00, 0.10, 0.20),
        )
        color = mix(color, Vec3(0.0, 0.0, 0.0), t / far)

        return color
        # return {uv.x, uv.y, sin(time) * 0.5 + 0.5}
