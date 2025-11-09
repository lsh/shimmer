"""
Ports of various time utilities from Rust,
since Mojo does not yet have a fleshed out
way to talk about time.
I removed a lot of good things in favor of reducing scope,
so don't use this for anything real or important.
"""

from os import abort
from time.time import _CLOCK_MONOTONIC, _clock_gettime, _CTimeSpec
from utils.numerics import FPUtils


alias NANOS_PER_SEC: UInt32 = 1_000_000_000
alias NANOS_PER_MILLI: UInt32 = 1_000_000
alias NANOS_PER_MICRO: UInt32 = 1_000
alias MILLIS_PER_SEC: UInt64 = 1_000
alias MICROS_PER_SEC: UInt64 = 1_000_000
alias SECS_PER_MINUTE: UInt64 = 60
alias SECS_PER_HOUR: Int64 = 3600
alias MINS_PER_HOUR: UInt64 = 60
alias HOURS_PER_DAY: UInt64 = 24
alias DAYS_PER_WEEK: UInt64 = 7


struct Duration(
    Copyable,
    Defaultable,
    ImplicitlyCopyable,
    Movable,
):
    var _secs: UInt64
    var _nanos: UInt32  # Always 0 <= nanos < NANOS_PER_SEC

    alias ZERO: Duration = Duration.from_nanos(0)
    """A duration of zero time."""

    alias MAX: Duration = Duration(UInt64.MAX, NANOS_PER_SEC - 1)
    """
    The maximum duration.
    """

    @always_inline
    fn __init__(out self):
        self._secs = 0
        self._nanos = 0

    @always_inline
    fn secs(self) -> Float64:
        return Float64(self.as_secs()) + Float64(self.subsec_nanos()) * 1e-9

    @always_inline
    fn __init__(out self, var secs: UInt64, var nanos: UInt32):
        if nanos < NANOS_PER_SEC:
            # SAFETY: nanos < NANOS_PER_SEC, therefore nanos is within the valid range
            self._secs = secs
            self._nanos = nanos
        else:
            secs = secs + UInt64(nanos / NANOS_PER_SEC)
            nanos = nanos % NANOS_PER_SEC
            # SAFETY: nanos % NANOS_PER_SEC < NANOS_PER_SEC, therefore nanos is within the valid range
            self._secs = secs
            self._nanos = nanos

    @always_inline
    @staticmethod
    fn from_secs(secs: UInt64) -> Self:
        """
        Creates a new `Duration` from the specified number of whole seconds.
        """
        return Self(secs, nanos=0)

    @always_inline
    @staticmethod
    fn from_millis(millis: UInt64) -> Duration:
        """
        Creates a new `Duration` from the specified number of milliseconds.
        """
        var secs = millis / MILLIS_PER_SEC
        var subsec_millis = UInt32(millis % MILLIS_PER_SEC)
        # SAFETY: (x % 1_000) * 1_000_000 < 1_000_000_000
        #         => x % 1_000 < 1_000
        var subsec_nanos = subsec_millis * NANOS_PER_MILLI

        return Duration(secs=secs, nanos=subsec_nanos)

    @always_inline
    @staticmethod
    fn from_micros(micros: UInt64) -> Duration:
        """Creates a new `Duration` from the specified number of microseconds.
        """
        var secs = micros / MICROS_PER_SEC
        var subsec_micros = UInt32(micros % MICROS_PER_SEC)

        var subsec_nanos = subsec_micros * NANOS_PER_MICRO

        return Duration(secs=secs, nanos=subsec_nanos)

    @always_inline
    @staticmethod
    fn from_nanos(nanos: UInt64) -> Duration:
        """
        Creates a new `Duration` from the specified number of nanoseconds.
        """
        var secs = nanos / UInt64(NANOS_PER_SEC)
        var subsec_nanos = UInt32(nanos) % NANOS_PER_SEC
        return Duration(secs=secs, nanos=subsec_nanos)

    @always_inline
    @staticmethod
    fn from_hours(hours: UInt64) -> Duration:
        """
        Creates a new `Duration` from the specified number of hours.
        """
        if hours > UInt64.MAX / (SECS_PER_MINUTE * MINS_PER_HOUR):
            abort("overflow in Duration.from_hours")

        return Duration.from_secs(hours * MINS_PER_HOUR * SECS_PER_MINUTE)

    @always_inline
    @staticmethod
    fn from_mins(mins: UInt64) -> Duration:
        """
        Creates a new `Duration` from the specified number of minutes.
        """
        if mins > UInt64.MAX / SECS_PER_MINUTE:
            abort("overflow in Duration.from_mins")

        return Duration.from_secs(mins * SECS_PER_MINUTE)

    @always_inline
    fn is_zero(self) -> Bool:
        """
        Returns true if this `Duration` spans no time.
        """
        return self._secs == 0 and self._nanos == 0

    @always_inline
    fn as_secs(self) -> UInt64:
        """
        Returns the number of _whole_ seconds contained by this `Duration`.
        """
        return self._secs

    @always_inline
    fn subsec_millis(self) -> UInt32:
        """
        Returns the fractional part of this `Duration`, in whole milliseconds.
        """
        return self._nanos / NANOS_PER_MILLI

    @always_inline
    fn subsec_micros(self) -> UInt32:
        """
        Returns the fractional part of this `Duration`, in whole microseconds.
        """
        return self._nanos / NANOS_PER_MICRO

    @always_inline
    fn subsec_nanos(self) -> UInt32:
        """
        Returns the fractional part of this `Duration`, in nanoseconds.
        """
        return self._nanos

    @always_inline
    fn as_millis(self) -> UInt128:
        """
        Returns the total number of whole milliseconds contained by this `Duration`.
        """
        return UInt128(self._secs) * UInt128(MILLIS_PER_SEC) + UInt128(
            self._nanos / NANOS_PER_MILLI
        )

    @always_inline
    fn as_micros(self) -> UInt128:
        """
        Returns the total number of whole microseconds contained by this `Duration`.
        """
        return UInt128(self._secs) * UInt128(MICROS_PER_SEC) + UInt128(
            self._nanos / NANOS_PER_MICRO
        )

    @always_inline
    fn as_nanos(self) -> UInt128:
        """
        Returns the total number of nanoseconds contained by this `Duration`.
        """
        return UInt128(self._secs) * UInt128(NANOS_PER_SEC) + UInt128(
            self._nanos
        )

    @always_inline
    fn __add__(self, rhs: Self) -> Self:
        var secs = self._secs + rhs._secs
        var nanos = self._nanos + rhs._nanos
        if nanos >= NANOS_PER_SEC:
            nanos -= NANOS_PER_SEC
            secs += 1
            debug_assert(nanos < NANOS_PER_SEC)
        return Duration(secs, nanos)

    @always_inline
    fn __sub__(self, rhs: Duration) -> Self:
        var secs = self._secs - rhs._secs
        var nanos: UInt32
        if self._nanos >= rhs._nanos:
            nanos = self._nanos - rhs._nanos
        else:
            secs -= 1
            nanos = self._nanos + NANOS_PER_SEC - rhs._nanos
        debug_assert(nanos < NANOS_PER_SEC)
        return Duration(secs, nanos)

    @always_inline
    fn __mul__(self, rhs: UInt32) -> Self:
        """
        Multiply nanoseconds as UInt64, because it cannot overflow that way.
        """
        var total_nanos = UInt64(self._nanos) * UInt64(rhs)
        var extra_secs = total_nanos / UInt64(NANOS_PER_SEC)
        var nanos = UInt32(total_nanos % UInt64(NANOS_PER_SEC))
        var secs = self._secs * UInt64(rhs) + extra_secs
        debug_assert(nanos < NANOS_PER_SEC)
        return Duration(secs, nanos)

    @always_inline
    fn __div__(self, rhs: UInt32) -> Duration:
        var (secs, extra_secs) = (
            self._secs / UInt64(rhs),
            self._secs % UInt64(rhs),
        )
        var (nanos, extra_nanos) = (self._nanos / rhs, self._nanos % rhs)
        nanos += UInt32(
            (extra_secs * UInt64(NANOS_PER_SEC) + UInt64(extra_nanos))
            / UInt64(rhs)
        )
        debug_assert(nanos < NANOS_PER_SEC)
        return Duration(secs, nanos)

    @always_inline
    fn as_secs_f64(self) -> Float64:
        """
        Returns the number of seconds contained by this `Duration` as `Float64`.

        The returned value includes the fractional (nanosecond) part of the duration.
        """
        return Float64(self._secs) + Float64(self._nanos) / Float64(
            NANOS_PER_SEC
        )

    @always_inline
    fn as_secs_f32(self) -> Float32:
        """
        Returns the number of seconds contained by this `Duration` as `Float32`.

        The returned value includes the fractional (nanosecond) part of the duration.
        """
        return Float32(self._secs) + Float32(self._nanos) / Float32(
            NANOS_PER_SEC
        )

    @always_inline
    @staticmethod
    fn from_secs_f64(secs: Float64) -> Duration:
        # Creates a new `Duration` from the specified number of seconds represented
        # as `f64`.
        try:
            return Duration.try_from_secs_f64(secs)
        except e:
            abort(String(e))
            return Duration.ZERO

    @always_inline
    @staticmethod
    fn from_secs_f32(secs: Float32) -> Duration:
        # Creates a new `Duration` from the specified number of seconds represented
        # as `f32`.
        try:
            return Duration.try_from_secs_f32(secs)
        except e:
            abort(String(e))
            return Duration.ZERO

    @always_inline
    fn __mul__(self, rhs: Float64) -> Duration:
        """
        Multiplies `Duration` by `f64`.
        """
        return Duration.from_secs_f64(rhs * self.as_secs_f64())

    @always_inline
    fn __mul__(self, rhs: Float32) -> Duration:
        """
        Multiplies `Duration` by `f32`.
        """
        return Duration.from_secs_f32(rhs * self.as_secs_f32())

    @always_inline
    fn __truediv__(self, rhs: Float64) -> Duration:
        """
        Divides `Duration` by `f64`.
        """
        return Duration.from_secs_f64(self.as_secs_f64() / rhs)

    @always_inline
    fn __truediv__(self, rhs: Float32) -> Duration:
        """
        Divides `Duration` by `f32`.
        """
        return Duration.from_secs_f32(self.as_secs_f32() / rhs)

    fn div_duration_f64(self, rhs: Duration) -> Float64:
        """
        Divides `Duration` by `Duration` and returns `Float64`.
        """
        var self_nanos = Float64(self._secs) * Float64(NANOS_PER_SEC) + Float64(
            self._nanos
        )
        var rhs_nanos = Float64(rhs._secs) * Float64(NANOS_PER_SEC) + Float64(
            rhs._nanos
        )
        return self_nanos / rhs_nanos

    @always_inline
    fn div_duration_f32(self, rhs: Duration) -> Float32:
        """
        Divides `Duration` by `Duration` and returns `Float32`.
        """
        var self_nanos = Float32(self._secs) * Float32(NANOS_PER_SEC) + Float32(
            self._nanos
        )
        var rhs_nanos = Float32(rhs._secs) * Float32(NANOS_PER_SEC) + Float32(
            rhs._nanos
        )
        return self_nanos / rhs_nanos

    @staticmethod
    fn try_from_secs_f32(secs: Float32) raises -> Self:
        """
        The checked version of [`from_secs_f32`].

        [`from_secs_f32`]: Duration.from_secs_f32

        This constructor will `raise` if `secs` is negative, overflows `Duration` or not finite.

        """
        return _try_from_secs[
            mant_bits=23,
            exp_bits=8,
            offset=41,
            bits_ty = DType.uint32,
            double_ty = DType.uint64,
        ](secs)

    @staticmethod
    fn try_from_secs_f64(secs: Float64) raises -> Self:
        return _try_from_secs[
            mant_bits=52,
            exp_bits=11,
            offset=44,
            bits_ty = DType.uint64,
            double_ty = DType.uint128,
        ](secs)


fn _try_from_secs[
    mant_bits: Int,
    exp_bits: Int,
    offset: Int,
    bits_ty: DType,
    double_ty: DType,
](var fsecs: Scalar) raises -> Duration:
    constrained[fsecs.dtype in (DType.float32, DType.float64)]()
    alias MIN_EXP: Int16 = 1 - (Int16(1) << exp_bits) / 2
    alias MANT_MASK: Scalar[bits_ty] = (1 << mant_bits) - 1
    alias EXP_MASK: Scalar[bits_ty] = (1 << exp_bits) - 1

    if fsecs < 0.0:
        raise Error("negative value")

    # let bits = fsecs.to_bits();
    var mant = FPUtils[fsecs.dtype].get_mantissa(fsecs)
    var exp = FPUtils[fsecs.dtype].get_exponent(fsecs)
    var nanos: UInt32
    var secs: UInt64

    if exp < -31:
        # the input represents less than 1ns and can not be rounded to it
        secs, nanos = 0, 0
    elif exp < 0:
        # the input is less than 1 second
        var t = Scalar[double_ty](mant) << (offset + exp)
        alias nanos_offset = mant_bits + offset
        var nanos_tmp = UInt128(NANOS_PER_SEC) * UInt128(t)
        nanos = UInt32(nanos_tmp >> nanos_offset)

        var rem_mask = (1 << nanos_offset) - 1
        var rem_msb_mask = 1 << (nanos_offset - 1)
        var rem = nanos_tmp & rem_mask
        var is_tie = rem == rem_msb_mask
        var is_even = (nanos & 1) == 0
        var rem_msb = nanos_tmp & rem_msb_mask == 0
        var add_ns = not (rem_msb or (is_even and is_tie))

        # f32 does not have enough precision to trigger the second branch
        # since it can not represent numbers between 0.999_999_940_395 and 1.0.
        nanos += UInt32(Int(add_ns))
        if (mant_bits == 23) or (nanos != NANOS_PER_SEC):
            secs, nanos = 0, nanos
        else:
            secs, nanos = 1, 0
    elif exp < mant_bits:
        secs = UInt64(mant >> (mant_bits - exp))
        var t = Scalar[double_ty]((mant << exp) & MANT_MASK)
        var nanos_offset = mant_bits
        var nanos_tmp = Scalar[double_ty](NANOS_PER_SEC) * t
        nanos = UInt32(nanos_tmp >> nanos_offset)

        var rem_mask = (1 << nanos_offset) - 1
        var rem_msb_mask = 1 << (nanos_offset - 1)
        var rem = nanos_tmp & rem_mask
        var is_tie = rem == rem_msb_mask
        var is_even = (nanos & 1) == 0
        var rem_msb = nanos_tmp & rem_msb_mask == 0
        var add_ns = not (rem_msb or (is_even and is_tie))

        # f32 does not have enough precision to trigger the second branch.
        # For example, it can not represent numbers between 1.999_999_880...
        # and 2.0. Bigger values result in even smaller precision of the
        # fractional part.
        nanos += UInt32(Int(add_ns))
        if (mant_bits == 23) or (nanos != NANOS_PER_SEC):
            pass
        else:
            secs, nanos = (secs + 1, 0)
    elif exp < 64:
        # the input has no fractional part
        secs = UInt64(mant) << (exp - mant_bits)
        secs, nanos = (secs, 0)
    else:
        raise Error("overflow or nan")

    return Duration(secs, nanos)


@fieldwise_init
struct Instant(Copyable, ImplicitlyCopyable, Movable):
    var _t: _CTimeSpec

    @staticmethod
    fn now() -> Instant:
        return Instant(_clock_gettime(_CLOCK_MONOTONIC))

    fn __sub__(self, other: Instant) -> Duration:
        return _sub_ctime_spec(self._t, other._t)

    fn __add__(self, other: Duration) -> Instant:
        return Self(_c_timespec_add_duration(self._t, other))

    fn __sub__(self, other: Duration) -> Self:
        return Self(_ctime_spec_sub_duration(self._t, other))

    fn duration_since(self, other: Instant) -> Duration:
        return self - other


fn _ge_timespec(lhs: _CTimeSpec, rhs: _CTimeSpec) -> Bool:
    if lhs.tv_sec > rhs.tv_sec:
        return True
    elif lhs.tv_sec == rhs.tv_sec:
        return lhs.tv_subsec >= rhs.tv_subsec
    return False


alias NSEC_PER_SEC: UInt64 = 1_000_000_000


fn _sub_ctime_spec(lhs: _CTimeSpec, other: _CTimeSpec) -> Duration:
    # When a >= b, the difference fits in u64.
    fn sub_ge_to_unsigned(a: Int64, b: Int64) -> UInt64:
        debug_assert(a >= b)
        return UInt64(a - b)

    var secs: UInt64
    var nsecs: UInt32
    if _ge_timespec(lhs, other):
        if lhs.tv_subsec >= other.tv_subsec:
            secs = sub_ge_to_unsigned(lhs.tv_sec, other.tv_sec)
            nsecs = lhs.tv_subsec - other.tv_subsec
        else:
            debug_assert(lhs.tv_subsec < other.tv_subsec)
            debug_assert(lhs.tv_sec > other.tv_sec)
            debug_assert(Int64(lhs.tv_sec) > Int64.MIN)
            secs = sub_ge_to_unsigned(lhs.tv_sec - 1, other.tv_sec)
            nsecs = lhs.tv_subsec + UInt32(NSEC_PER_SEC) - other.tv_subsec

        return Duration(secs, nsecs)
    return Duration()


fn _c_timespec_add_duration(lhs: _CTimeSpec, other: Duration) -> _CTimeSpec:
    var secs = lhs.tv_sec + other.as_secs()

    # Nano calculations can't overflow because nanos are <1B which fit
    # in a u32.

    var nsec = other.subsec_nanos() + lhs.tv_subsec
    if nsec >= UInt32(NSEC_PER_SEC):
        nsec -= UInt32(NSEC_PER_SEC)
        secs += 1
    return _CTimeSpec(Int(secs), Int(nsec))


fn _ctime_spec_sub_duration(lhs: _CTimeSpec, other: Duration) -> _CTimeSpec:
    var secs = lhs.tv_sec - (other.as_secs())

    # Similar to above, nanos can't overflow.
    var nsec = Int32(lhs.tv_subsec) - Int32(other.subsec_nanos())
    if nsec < 0:
        nsec += Int32(NSEC_PER_SEC)
        secs -= 1
    return _CTimeSpec(Int(secs), Int(nsec))
