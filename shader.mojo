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


@always_inline
fn calc_normal[
    df: fn (var Vec3, Float32) -> Float32, eps: Float32 = 0.005
](p: Vec3, time: Float32) -> Vec3:
    return Vec3(
        df(p + Vec3(eps, 0.0, 0.0), time) - df(p - Vec3(eps, 0.0, 0.0), time),
        df(p + Vec3(0.0, eps, 0.0), time) - df(p - Vec3(0.0, eps, 0.0), time),
        df(p + Vec3(0.0, 0.0, eps), time) - df(p - Vec3(0.0, 0.0, eps), time),
    ).normalize()


@always_inline
fn rot2d(p: Vec2, a: Float32) -> Vec2:
    var c = cos(a)
    var s = sin(a)
    return {p.x * c - p.y * s, p.x * s + p.y * c}


@always_inline
fn map(var p: Vec3, time: Float32) -> Float32:
    var q = p
    var p2 = rot2d({p.x, p.y}, q.z * 0.1 + time * 0.1)
    p = Vec3(p2.x, p2.y, p.z)
    p = (p % 2.0) - 1.0
    return p.length() - 0.4


@always_inline
fn trace[
    df: fn (var Vec3, Float32) -> Float32,
    far: Float32 = 20.0,
    eps: Float32 = 0.001,
](ro: Vec3, rd: Vec3, time: Float32) -> Float32:
    var t = Float32(0)
    for _ in range(250):
        var p = ro + rd * t
        var m = map(p, time)
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
fn main_image[
    far: Float32 = 20.0
](uv: Vec2, width: Int, height: Int, time: Float32) -> Vec3:
    var q = uv * 2.0 - 1.0
    (UnsafePointer(to=q).bitcast[Float32]())[] *= Float32(width) / Float32(
        height
    )
    var ro = Vec3(0.0, 0.0, time + 5.0)
    var cv = ro + Vec3(0.0, 0.0, 4.0)
    var rd = calc_cam(q, ro, cv, 0.4)
    var t = trace[map, far=far](ro, rd, time)
    var p = ro + rd * t
    var n = calc_normal[map](p, time)
    if t > far:
        return Vec3(0.0, 0.0, 0.0)
    alias lp = Vec3(0.0, 0.5, 0.0)
    var ld = (lp - p).normalize()
    var diff = n.dot(ld) * 0.5 + 0.5
    diff *= diff
    var color = Vec3(diff, diff, diff)
    color = mix(color, Vec3(0.0, 1.0, 0.0), t / far)

    return color
    # return {uv.x, uv.y, sin(time) * 0.5 + 0.5}


fn kernel(ptr: UnsafePointer[UInt32], width: Int, height: Int, time: Float32):
    var idx = Int(global_idx.x)
    if idx > Int(width * height):
        return

    var x = idx % width
    var y = idx // width

    var uv = Vec2(
        Float32(x) / Float32(width),
        Float32(y) / Float32(height),
    )
    var col = main_image(uv, width, height, time)

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
        ctx.enqueue_function_checked[kernel, kernel](
            buffer,
            uniforms.width,
            uniforms.height,
            uniforms.time,
            grid_dim=ceildiv(uniforms.width * uniforms.height, 256),
            block_dim=256,
        )
    except e:
        print("Error running shader", e)
