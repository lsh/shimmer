from builtin.device_passable import DevicePassable
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
