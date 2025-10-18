@always_inline
fn map(var p: Vec3, uniforms: Uniforms) -> Float32:
    var q = p
    var p2 = rot2d({p.x, p.y}, q.z * 0.1 + uniforms.time * 0.25)
    p = Vec3(p2.x, p2.y, p.z)
    p = (p % 2.0) - 1.0
    return p.length() - 0.4 - uniforms.audio.y


struct Spheres(Shader):
    @always_inline
    @staticmethod
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
        alias lp = Vec3(0.0, 0.5, 0.0)
        var ld = (lp - p).normalize()
        var diff = n.dot(ld) * 0.5 + 0.5
        diff *= diff
        var color = Vec3(diff, diff, diff)
        color = mix(color, Vec3(0.0, 0.0, 0.0), t / far)

        return color
        # return {uv.x, uv.y, sin(time) * 0.5 + 0.5}
