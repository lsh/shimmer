import math
import builtin
from builtin.device_passable import DevicePassable


@fieldwise_init
@register_passable("trivial")
struct Vec3(Copyable, DevicePassable, Movable, Writable):
    var _value: SIMD[DType.float32, 4]

    alias device_type: AnyType = Self

    fn _to_device_type(self, target: OpaquePointer):
        target.bitcast[Self.device_type]()[] = self

    @staticmethod
    fn get_type_name() -> String:
        return "Vec3"

    @staticmethod
    fn get_device_type_name() -> String:
        return "Vec3"

    @always_inline
    fn __init__(out self):
        self._value = {0, 0, 0, 0}

    @always_inline
    fn __init__(out self, x: Float32, y: Float32, z: Float32):
        self._value = {x, y, z, 0}

    @always_inline
    fn __init__(out self, val: Float32):
        self._value = {val, val, val, 0}

    @always_inline
    fn __getitem__[IndexType: Intable](ref self, val: IndexType) -> Float32:
        return self._value[Int(val)]

    @always_inline
    fn __getattr__[val: StringLiteral](self) -> Float32:
        constrained[val in ["x", "y", "z"]]()

        @parameter
        if val == "x":
            return self._value[0]
        elif val == "y":
            return self._value[1]
        elif val == "z":
            return self._value[2]

        # unreachable
        return self._value[3]

    @always_inline
    fn __neg__(self) -> Self:
        return Self(-self.x, -self.y, -self.z)

    @always_inline
    fn __add__(self, rhs: Self) -> Vec3:
        return Self(self._value + rhs._value)

    @always_inline
    fn __sub__(self, rhs: Self) -> Vec3:
        return Self(self._value - rhs._value)

    @always_inline
    fn __mul__(self, rhs: Self) -> Vec3:
        return Self(self._value * rhs._value)

    @always_inline
    fn __div__(self, rhs: Self) -> Vec3:
        return Self(self._value / rhs._value)

    @always_inline
    fn __truediv__(self, rhs: Self) -> Vec3:
        return Self(self._value // rhs._value)

    @always_inline
    fn __add__(self, rhs: Float32) -> Vec3:
        return Self(self._value + rhs)

    @always_inline
    fn __sub__(self, rhs: Float32) -> Vec3:
        return Self(self._value - rhs)

    @always_inline
    fn __mul__(self, rhs: Float32) -> Vec3:
        return Self(self._value * rhs)

    @always_inline
    fn __div__(self, rhs: Float32) -> Vec3:
        return Self(self._value // rhs)

    @always_inline
    fn __truediv__(self, rhs: Float32) -> Vec3:
        return Self(self._value / rhs)

    @always_inline
    fn __mod__(self, rhs: Float32) -> Vec3:
        return Self(self._value % rhs)

    @always_inline
    fn __iadd__(mut self, rhs: Self):
        self._value += rhs._value

    @always_inline
    fn __isub__(mut self, rhs: Self):
        self._value -= rhs._value

    @always_inline
    fn __imul__(mut self, rhs: Self):
        self._value *= rhs._value

    @always_inline
    fn __idiv__(mut self, rhs: Self):
        self._value //= rhs._value

    @always_inline
    fn __itruediv__(mut self, rhs: Self):
        self._value /= rhs._value

    @always_inline
    fn __iadd__(mut self, rhs: Float32):
        self._value += rhs

    @always_inline
    fn __isub__(mut self, rhs: Float32):
        self._value -= rhs

    @always_inline
    fn __imul__(mut self, rhs: Float32):
        self._value *= rhs

    @always_inline
    fn __idiv__(mut self, rhs: Float32):
        self._value //= rhs

    @always_inline
    fn __itruediv__(mut self, rhs: Float32):
        self._value /= rhs

    @always_inline
    fn __radd__(self, rhs: Float32) -> Vec3:
        return Self(self._value + rhs)

    @always_inline
    fn __rsub__(self, rhs: Float32) -> Vec3:
        return Self(self._value - rhs)

    @always_inline
    fn __rmul__(self, rhs: Float32) -> Vec3:
        return Self(self._value * rhs)

    @always_inline
    fn __rdiv__(self, rhs: Float32) -> Vec3:
        return Self(rhs // self._value)

    @always_inline
    fn __rtruediv__(self, rhs: Float32) -> Vec3:
        return Self(rhs / self._value)

    @always_inline
    fn abs(self) -> Vec3:
        return Self(abs(self.x), abs(self.y), abs(self.z))

    @always_inline
    fn clamp(self, min_val: Float32, max_val: Float32) -> Vec3:
        return Vec3(
            math.clamp(self.x, min_val, max_val),
            math.clamp(self.y, min_val, max_val),
            math.clamp(self.z, min_val, max_val),
        )

    @always_inline
    fn dot(self, rhs: Self) -> Float32:
        return (self.x * rhs.x) + (self.y * rhs.y) + (self.z * rhs.z)

    @always_inline
    fn cross(self, rhs: Self) -> Vec3:
        return {
            self.y * rhs.z - rhs.y * self.z,
            self.z * rhs.x - rhs.z * self.x,
            self.x * rhs.y - rhs.x * self.y,
        }

    @always_inline
    fn length(self) -> Float32:
        return math.sqrt(self.dot(self))

    @always_inline
    fn length_squared(self) -> Float32:
        return self.dot(self)

    @always_inline
    fn length_recip(self) -> Float32:
        return 1.0 / self.length()

    # Computes the Euclidean distance between two points in space.
    @always_inline
    fn distance(self, rhs: Self) -> Float32:
        return (self - rhs).length()

    # Compute the squared euclidean distance between two points in space.
    @always_inline
    fn distance_squared(self, rhs: Self) -> Float32:
        return (self - rhs).length_squared()

    @always_inline
    fn min(self, b: Self) -> Self:
        return Vec3(builtin.math.min(self._value, b._value))

    @always_inline
    fn max(self, b: Self) -> Self:
        return Vec3(builtin.math.max(self._value, b._value))

    @always_inline
    fn cos(self) -> Self:
        return Vec3(math.cos(self._value))

    @always_inline
    fn sin(self) -> Self:
        return Vec3(math.sin(self._value))

    @always_inline
    fn normalize(self) -> Vec3:
        return self * self.length_recip()

    @always_inline
    fn tan(self) -> Self:
        return Vec3(math.tan(self._value))

    @always_inline
    fn reflect(self, normal: Self) -> Self:
        return self - 2.0 * self.dot(normal) * normal

    # Branchless refract candidate: sqrtk is zero if total internal reflection
    @always_inline
    fn refract_branchless(self, n: Self, etai_over_etat: Float32) -> Self:
        var dt = self.dot(n)
        var k = 1.0 - etai_over_etat * etai_over_etat * (1.0 - dt * dt)
        var sqrtk = math.sqrt(max(k, 0.0))
        return etai_over_etat * (self - n * dt) - n * sqrtk

    fn floor(self) -> Self:
        return Vec3(math.floor(self.x), math.floor(self.y), math.floor(self.z))

    fn fract(self) -> Self:
        return self - self.floor()

    fn write_to(self, mut w: Some[Writer]):
        w.write("Vec3(")
        w.write(self.x)
        w.write(", ")
        w.write(self.y)
        w.write(", ")
        w.write(self.z)
        w.write(")")


@fieldwise_init
@register_passable("trivial")
struct Vec2(Copyable, DevicePassable, Movable):
    var _value: SIMD[DType.float32, 2]

    alias device_type: AnyType = Self

    fn _to_device_type(self, target: OpaquePointer):
        target.bitcast[Self.device_type]()[] = self

    @staticmethod
    fn get_type_name() -> String:
        return "Vec2"

    @staticmethod
    fn get_device_type_name() -> String:
        return "Vec2"

    @always_inline
    fn __init__(out self):
        self._value = {0, 0}

    @always_inline
    fn __init__(out self, x: Float32, y: Float32):
        self._value = {x, y}

    @always_inline
    fn __init__(out self, val: Float32):
        self._value = {val, val}

    @always_inline
    fn __getitem__[IndexType: Intable](self, val: IndexType) -> Float32:
        return self._value[Int(val)]

    @always_inline
    fn __getattr__[val: StringLiteral](self) -> Float32:
        constrained[val in ["x", "y"]]()

        @parameter
        if val == "x":
            return self._value[0]
        else:
            return self._value[1]

    @always_inline
    fn __neg__(self) -> Self:
        return Self(-self.x, -self.y)

    @always_inline
    fn __add__(self, rhs: Self) -> Self:
        return Self(self._value + rhs._value)

    @always_inline
    fn __sub__(self, rhs: Self) -> Self:
        return Self(self._value - rhs._value)

    @always_inline
    fn __mul__(self, rhs: Self) -> Self:
        return Self(self._value * rhs._value)

    @always_inline
    fn __div__(self, rhs: Self) -> Self:
        return Self(self._value / rhs._value)

    @always_inline
    fn __truediv__(self, rhs: Self) -> Self:
        return Self(self._value // rhs._value)

    @always_inline
    fn __add__(self, rhs: Float32) -> Self:
        return Self(self._value + rhs)

    @always_inline
    fn __sub__(self, rhs: Float32) -> Self:
        return Self(self._value - rhs)

    @always_inline
    fn __mul__(self, rhs: Float32) -> Self:
        return Self(self._value * rhs)

    @always_inline
    fn __div__(self, rhs: Float32) -> Self:
        return Self(self._value // rhs)

    @always_inline
    fn __truediv__(self, rhs: Float32) -> Self:
        return Self(self._value / rhs)

    @always_inline
    fn __iadd__(mut self, rhs: Self):
        self._value += rhs._value

    @always_inline
    fn __isub__(mut self, rhs: Self):
        self._value -= rhs._value

    @always_inline
    fn __imul__(mut self, rhs: Self):
        self._value *= rhs._value

    @always_inline
    fn __idiv__(mut self, rhs: Self):
        self._value //= rhs._value

    @always_inline
    fn __itruediv__(mut self, rhs: Self):
        self._value /= rhs._value

    @always_inline
    fn __iadd__(mut self, rhs: Float32):
        self._value += rhs

    @always_inline
    fn __isub__(mut self, rhs: Float32):
        self._value -= rhs

    @always_inline
    fn __imul__(mut self, rhs: Float32):
        self._value *= rhs

    @always_inline
    fn __idiv__(mut self, rhs: Float32):
        self._value //= rhs

    @always_inline
    fn __itruediv__(mut self, rhs: Float32):
        self._value /= rhs

    @always_inline
    fn __radd__(self, rhs: Float32) -> Self:
        return Self(self._value + rhs)

    @always_inline
    fn __rmul__(self, rhs: Float32) -> Self:
        return Self(self._value * rhs)

    @always_inline
    fn __rdiv__(self, rhs: Float32) -> Self:
        return Self(rhs // self._value)

    @always_inline
    fn __rtruediv__(self, rhs: Float32) -> Self:
        return Self(rhs / self._value)

    @always_inline
    fn abs(self) -> Vec2:
        return Self(abs(self.x), abs(self.y))

    @always_inline
    fn dot(self, rhs: Self) -> Float32:
        return (self.x * rhs.x) + (self.y * rhs.y)

    @always_inline
    fn length(self) -> Float32:
        return math.sqrt(self.dot(self))

    @always_inline
    fn length_squared(self) -> Float32:
        return self.dot(self)

    @always_inline
    fn length_recip(self) -> Float32:
        return 1.0 / self.length()

    # Computes the Euclidean distance between two points in space.
    @always_inline
    fn distance(self, rhs: Self) -> Float32:
        return (self - rhs).length()

    # Compute the squared euclidean distance between two points in space.
    @always_inline
    fn distance_squared(self, rhs: Self) -> Float32:
        return (self - rhs).length_squared()

    @always_inline
    fn min(self, b: Self) -> Self:
        return Vec2(builtin.math.min(self._value, b._value))

    @always_inline
    fn max(self, b: Self) -> Self:
        return Vec2(builtin.math.max(self._value, b._value))

    @always_inline
    fn cos(self) -> Self:
        return Vec2(math.cos(self._value))

    @always_inline
    fn sin(self) -> Self:
        return Vec2(math.sin(self._value))

    @always_inline
    fn normalize(self) -> Vec2:
        return self * self.length_recip()

    @always_inline
    fn tan(self) -> Self:
        return Vec2(math.tan(self._value))

    @always_inline
    fn reflect(self, normal: Self) -> Self:
        return self - 2.0 * self.dot(normal) * normal

    # Branchless refract candidate: sqrtk is zero if total internal reflection
    @always_inline
    fn refract_branchless(self, n: Self, etai_over_etat: Float32) -> Self:
        var dt = self.dot(n)
        var k = 1.0 - etai_over_etat * etai_over_etat * (1.0 - dt * dt)
        var sqrtk = math.sqrt(max(k, 0.0))
        return etai_over_etat * (self - n * dt) - n * sqrtk


@fieldwise_init
@register_passable("trivial")
struct Vec4(Copyable, DevicePassable, Movable):
    var _value: SIMD[DType.float32, 4]

    alias device_type: AnyType = Self

    fn _to_device_type(self, target: OpaquePointer):
        target.bitcast[Self.device_type]()[] = self

    @staticmethod
    fn get_type_name() -> String:
        return "Vec4"

    @staticmethod
    fn get_device_type_name() -> String:
        return "Vec4"

    @always_inline
    fn __init__(out self):
        self._value = {0, 0, 0, 0}

    @always_inline
    fn __init__(out self, x: Float32, y: Float32, z: Float32, w: Float32):
        self._value = {x, y, z, w}

    @always_inline
    fn __init__(out self, val: Float32):
        self._value = {val, val, val, val}

    @always_inline
    fn __getitem__[IndexType: Intable](self, val: IndexType) -> Float32:
        return self._value[Int(val)]

    @always_inline
    fn __getattr__[val: StringLiteral](self) -> Float32:
        constrained[val in ["x", "y", "z", "w"]]()

        @parameter
        if val == "x":
            return self._value[0]
        elif val == "y":
            return self._value[1]
        elif val == "z":
            return self._value[2]

        # unreachable
        return self._value[3]

    @always_inline
    fn __neg__(self) -> Self:
        return Self(-self.x, -self.y, -self.z, -self.w)

    @always_inline
    fn __add__(self, rhs: Self) -> Self:
        return Self(self._value + rhs._value)

    @always_inline
    fn __sub__(self, rhs: Self) -> Self:
        return Self(self._value - rhs._value)

    @always_inline
    fn __mul__(self, rhs: Self) -> Self:
        return Self(self._value * rhs._value)

    @always_inline
    fn __div__(self, rhs: Self) -> Self:
        return Self(self._value / rhs._value)

    @always_inline
    fn __truediv__(self, rhs: Self) -> Self:
        return Self(self._value // rhs._value)

    @always_inline
    fn __add__(self, rhs: Float32) -> Self:
        return Self(self._value + rhs)

    @always_inline
    fn __sub__(self, rhs: Float32) -> Self:
        return Self(self._value - rhs)

    @always_inline
    fn __mul__(self, rhs: Float32) -> Self:
        return Self(self._value * rhs)

    @always_inline
    fn __div__(self, rhs: Float32) -> Self:
        return Self(self._value // rhs)

    @always_inline
    fn __truediv__(self, rhs: Float32) -> Self:
        return Self(self._value / rhs)

    @always_inline
    fn __iadd__(mut self, rhs: Self):
        self._value += rhs._value

    @always_inline
    fn __isub__(mut self, rhs: Self):
        self._value -= rhs._value

    @always_inline
    fn __imul__(mut self, rhs: Self):
        self._value *= rhs._value

    @always_inline
    fn __idiv__(mut self, rhs: Self):
        self._value //= rhs._value

    @always_inline
    fn __itruediv__(mut self, rhs: Self):
        self._value /= rhs._value

    @always_inline
    fn __iadd__(mut self, rhs: Float32):
        self._value += rhs

    @always_inline
    fn __isub__(mut self, rhs: Float32):
        self._value -= rhs

    @always_inline
    fn __imul__(mut self, rhs: Float32):
        self._value *= rhs

    @always_inline
    fn __idiv__(mut self, rhs: Float32):
        self._value //= rhs

    @always_inline
    fn __itruediv__(mut self, rhs: Float32):
        self._value /= rhs

    @always_inline
    fn __radd__(self, rhs: Float32) -> Self:
        return Self(self._value + rhs)

    @always_inline
    fn __rmul__(self, rhs: Float32) -> Self:
        return Self(self._value * rhs)

    @always_inline
    fn __rdiv__(self, rhs: Float32) -> Self:
        return Self(rhs // self._value)

    @always_inline
    fn __rtruediv__(self, rhs: Float32) -> Self:
        return Self(rhs / self._value)

    @always_inline
    fn dot(self, rhs: Self) -> Float32:
        return (
            (self.x * rhs.x)
            + (self.y * rhs.y)
            + (self.z * rhs.z)
            + (self.w * rhs.w)
        )

    @always_inline
    fn length(self) -> Float32:
        return math.sqrt(self.dot(self))

    @always_inline
    fn length_squared(self) -> Float32:
        return self.dot(self)

    @always_inline
    fn length_recip(self) -> Float32:
        return 1.0 / self.length()

    # Computes the Euclidean distance between two points in space.
    @always_inline
    fn distance(self, rhs: Self) -> Float32:
        return (self - rhs).length()

    # Compute the squared euclidean distance between two points in space.
    @always_inline
    fn distance_squared(self, rhs: Self) -> Float32:
        return (self - rhs).length_squared()

    @always_inline
    fn min(self, b: Self) -> Self:
        return Vec4(builtin.math.min(self._value, b._value))

    @always_inline
    fn max(self, b: Self) -> Self:
        return Vec4(builtin.math.max(self._value, b._value))

    @always_inline
    fn cos(self) -> Self:
        return Vec4(math.cos(self._value))

    @always_inline
    fn sin(self) -> Self:
        return Vec4(math.sin(self._value))

    @always_inline
    fn normalize(self) -> Self:
        return self * self.length_recip()

    @always_inline
    fn tan(self) -> Self:
        return Vec4(math.tan(self._value))

    @always_inline
    fn reflect(self, normal: Self) -> Self:
        return self - 2.0 * self.dot(normal) * normal

    # Branchless refract candidate: sqrtk is zero if total internal reflection
    @always_inline
    fn refract_branchless(self, n: Self, etai_over_etat: Float32) -> Self:
        var dt = self.dot(n)
        var k = 1.0 - etai_over_etat * etai_over_etat * (1.0 - dt * dt)
        var sqrtk = math.sqrt(max(k, 0.0))
        return etai_over_etat * (self - n * dt) - n * sqrtk

    @always_inline
    fn abs(self) -> Vec4:
        return Self(abs(self.x), abs(self.y), abs(self.z), abs(self.w))
