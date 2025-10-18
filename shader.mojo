from shader_util import Uniforms
from vec import *

from gpu.host import DeviceContext, DeviceBuffer
from gpu import global_idx
from math import ceildiv, cos, sin


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


fn palette(t: Float32, a: Vec3, b: Vec3, c: Vec3, d: Vec3) -> Vec3:
    return a + b * (
        Vec3(1.0, 1.0, 1.0) * (2.0 * 3.14159265 * (c * t + d)).cos()
    )


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
fn rot2d(p: Vec2, a: Float32) -> Vec2:
    var c = cos(a)
    var s = sin(a)
    return {p.x * c - p.y * s, p.x * s + p.y * c}


@always_inline
fn map(var p: Vec3, uniforms: Uniforms) -> Float32:
    return (
        (p.abs() + p.abs().sin() + uniforms.time).cos().length()
        - 0.5
        - uniforms.audio.y * 0.5
    )


@always_inline
fn trace[
    df: fn (var Vec3, Uniforms) -> Float32,
    far: Float32 = 20.0,
    eps: Float32 = 0.001,
](ro: Vec3, rd: Vec3, uniforms: Uniforms) -> Float32:
    var t = Float32(0)
    for _ in range(250):
        var p = ro + rd * t
        var m = map(p, uniforms)
        t += m * 0.75
        if t > far or m < eps:
            break
    return t


@always_inline
fn calc_cam(uv: Vec2, ro: Vec3, rd: Vec3, fov: Float32) -> Vec3:
    var cu = Vec3(0.0, 1.0, 0.0).normalize()
    var z = (cu - ro).normalize()
    var x = cu.cross(z).normalize()
    var y = z.cross(x)
    return (z + fov * uv.x * x + fov * uv.y * y).normalize()


@always_inline
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


fn kernel(ptr: UnsafePointer[UInt32], uniforms: Uniforms):
    var idx = Int(global_idx.x)
    if idx > Int(uniforms.width * uniforms.height):
        return

    var x = idx % Int(uniforms.width)
    var y = idx // Int(uniforms.width)

    var uv = Vec2(
        Float32(x) / Float32(uniforms.width),
        Float32(y) / Float32(uniforms.height),
    )
    var col = main_image(uv, uniforms)

    var r = UInt8(col.x * 255.0)
    var g = UInt8(col.y * 255.0)
    var b = UInt8(col.z * 255.0)
    var a = UInt8(255)
    ptr.bitcast[SIMD[DType.uint8, 4]]()[idx] = {b, g, r, a}


@export(ABI="C")
fn run_shader(
    mut buffer: DeviceBuffer[DType.uint32],
    uniforms: Uniforms,
    ctx: DeviceContext,
):
    try:
        ctx.enqueue_function_experimental[kernel](
            buffer,
            uniforms,
            grid_dim=ceildiv(uniforms.width * uniforms.height, 256),
            block_dim=256,
        )
    except e:
        print("Error running shader", e)
