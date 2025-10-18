from builtin.device_passable import DevicePassable
from math import cos, sin

from vec import *


@fieldwise_init
@register_passable("trivial")
struct Uniforms(Copyable, DevicePassable, ImplicitlyCopyable, Movable):
    var width: Int
    var height: Int
    var time: Float32
    var audio: Vec3

    alias device_type: AnyType = Self

    fn _to_device_type(self, target: OpaquePointer):
        target.bitcast[Self.device_type]()[] = self

    @staticmethod
    fn get_type_name() -> String:
        return "Uniforms"

    @staticmethod
    fn get_device_type_name() -> String:
        return "Uniforms"


trait Shader:
    @staticmethod
    fn main_image[far: Float32 = 20.0](uv: Vec2, uniforms: Uniforms) -> Vec3:
        ...


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
fn rot2d(p: Vec2, a: Float32) -> Vec2:
    var c = cos(a)
    var s = sin(a)
    return {p.x * c - p.y * s, p.x * s + p.y * c}


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
