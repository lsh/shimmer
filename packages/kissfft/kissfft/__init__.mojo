"""
KISS FFT - Keep It Simple, Stupid FFT
Copyright (c) 2003-2010, Mark Borgerding. All rights reserved.
Converted to Mojo (Floating-Point Only)

SPDX-License-Identifier: BSD-3-Clause
"""

from complex import ComplexScalar, ComplexSIMD
from math import cos, sin, sqrt, pi
from memory import UnsafePointer, memcpy


alias MAXFACTORS = 32


__extension ComplexSIMD:
    fn exp(self, phase: Float64) -> Self:
        """Complex exponential: e^(i*phase) = cos(phase) + i*sin(phase)"""
        return Self(
            cos(phase).cast[Self.dtype](), sin(phase).cast[Self.dtype]()
        )


struct KissFFTState[dtype: DType]:
    """FFT state structure with transform methods."""

    var nfft: Int
    var inverse: Bool
    var factors: InlineArray[Int32, 2 * MAXFACTORS]
    var twiddles: List[ComplexScalar[dtype]]

    fn __init__(out self, nfft: Int, inverse: Bool = False):
        """Initialize FFT state and compute twiddle factors."""
        self.nfft = nfft
        self.inverse = inverse
        self.factors = InlineArray[Int32, 2 * MAXFACTORS](uninitialized=True)
        self.twiddles = List[ComplexScalar[dtype]]()

        # Allocate and compute twiddle factors
        self.twiddles.reserve(nfft)
        var phase_multiplier: Float64 = -2.0 * pi / Float64(nfft)
        if inverse:
            phase_multiplier *= -1.0

        for i in range(nfft):
            var phase = phase_multiplier * Float64(i)
            self.twiddles.append(
                ComplexScalar[dtype](
                    cos(phase).cast[dtype](), sin(phase).cast[dtype]()
                )
            )

        # Factor the FFT size
        self._factor(nfft)

    fn transform(
        mut self,
        fin: Span[ComplexScalar[dtype]],
        fout: Span[mut=True, ComplexScalar[dtype]],
        in_stride: Int = 1,
    ):
        """Perform FFT transform.

        Args:
            fin: Input buffer (complex samples).
            fout: Output buffer (complex spectrum).
            in_stride: Stride for reading input (default 1).
        """
        if fin == fout:
            # Need temporary buffer for in-place operation
            var tmpbuf = List[ComplexScalar[dtype]](capacity=self.nfft)
            self._work(tmpbuf, fin, 1, in_stride, 0)
            memcpy(
                dest=fout.unsafe_ptr(),
                src=tmpbuf.unsafe_ptr(),
                count=Int(self.nfft),
            )
        else:
            self._work(fout, fin, 1, in_stride, 0)

    # Private butterfly methods

    fn _bfly2(
        self,
        var fout: Span[mut=True, ComplexScalar[dtype]],
        fstride: Int32,
        m: Int32,
    ):
        """Radix-2 butterfly."""
        var fout2 = fout[Int(m) :]
        var tw_idx = Int32(0)

        for _ in range(m):
            var t = fout2[0] * self.twiddles[tw_idx]
            tw_idx += fstride

            fout2[0] = fout[0] - t
            fout[0] = fout[0] + t

            fout2 = fout2[1:]
            fout = fout[1:]

    fn _bfly3(
        self,
        var fout: Span[mut=True, ComplexScalar[dtype]],
        fstride: Int32,
        m: Int32,
    ):
        """Radix-3 butterfly."""
        var m2 = 2 * m
        var scratch = InlineArray[ComplexScalar[dtype], 5](uninitialized=True)
        var epi3 = self.twiddles[fstride * m]
        var tw1_idx = Int32(0)
        var tw2_idx = Int32(0)

        var k = m
        while k > 0:
            scratch[1] = fout[m] * self.twiddles[tw1_idx]
            scratch[2] = fout[m2] * self.twiddles[tw2_idx]

            scratch[3] = scratch[1] + scratch[2]
            scratch[0] = scratch[1] - scratch[2]

            tw1_idx += fstride
            tw2_idx += fstride * 2

            fout[m] = ComplexScalar[dtype](
                fout[0].re - scratch[3].re * 0.5,
                fout[0].im - scratch[3].im * 0.5,
            )

            scratch[0] = ComplexScalar[dtype](
                scratch[0].re * epi3.im, scratch[0].im * epi3.im
            )

            fout[0] = fout[0] + scratch[3]

            fout[m2] = ComplexScalar[dtype](
                fout[m].re + scratch[0].im, fout[m].im - scratch[0].re
            )

            fout[m] = ComplexScalar[dtype](
                fout[m].re - scratch[0].im, fout[m].im + scratch[0].re
            )

            fout = fout[1:]
            k -= 1

    fn _bfly4(
        self,
        var fout: Span[mut=True, ComplexScalar[dtype]],
        fstride: Int32,
        m: Int32,
    ):
        """Radix-4 butterfly."""
        var m2 = 2 * m
        var m3 = 3 * m
        var scratch = InlineArray[ComplexScalar[dtype], 6](uninitialized=True)

        var tw1_idx = Int32(0)
        var tw2_idx = Int32(0)
        var tw3_idx = Int32(0)

        var k = m
        while k > 0:
            scratch[0] = fout[m] * self.twiddles[tw1_idx]
            scratch[1] = fout[m2] * self.twiddles[tw2_idx]
            scratch[2] = fout[m3] * self.twiddles[tw3_idx]

            scratch[5] = fout[0] - scratch[1]
            fout[0] = fout[0] + scratch[1]
            scratch[3] = scratch[0] + scratch[2]
            scratch[4] = scratch[0] - scratch[2]
            fout[m2] = fout[0] - scratch[3]

            tw1_idx += fstride
            tw2_idx += fstride * 2
            tw3_idx += fstride * 3

            fout[0] = fout[0] + scratch[3]

            if self.inverse:
                fout[m] = ComplexScalar[dtype](
                    scratch[5].re - scratch[4].im, scratch[5].im + scratch[4].re
                )
                fout[m3] = ComplexScalar[dtype](
                    scratch[5].re + scratch[4].im, scratch[5].im - scratch[4].re
                )
            else:
                fout[m] = ComplexScalar[dtype](
                    scratch[5].re + scratch[4].im, scratch[5].im - scratch[4].re
                )
                fout[m3] = ComplexScalar[dtype](
                    scratch[5].re - scratch[4].im, scratch[5].im + scratch[4].re
                )

            fout = fout[1:]
            k -= 1

    fn _bfly5(
        self,
        var fout: Span[mut=True, ComplexScalar[dtype]],
        fstride: Int32,
        m: Int32,
    ):
        """Radix-5 butterfly."""
        var scratch = InlineArray[ComplexScalar[dtype], 13](uninitialized=True)
        var ya = self.twiddles[fstride * m]
        var yb = self.twiddles[fstride * 2 * m]

        var fout0 = fout
        var fout1 = fout[Int(m) :]
        var fout2 = fout[2 * Int(m) :]
        var fout3 = fout[3 * Int(m) :]
        var fout4 = fout[4 * Int(m) :]

        for u in range(m):
            scratch[0] = fout0[0]

            scratch[1] = fout1[0] * self.twiddles[u * fstride]
            scratch[2] = fout2[0] * self.twiddles[2 * u * fstride]
            scratch[3] = fout3[0] * self.twiddles[3 * u * fstride]
            scratch[4] = fout4[0] * self.twiddles[4 * u * fstride]

            scratch[7] = scratch[1] + scratch[4]
            scratch[10] = scratch[1] - scratch[4]
            scratch[8] = scratch[2] + scratch[3]
            scratch[9] = scratch[2] - scratch[3]

            fout0[0] = ComplexScalar[dtype](
                fout0[0].re + scratch[7].re + scratch[8].re,
                fout0[0].im + scratch[7].im + scratch[8].im,
            )

            scratch[5] = ComplexScalar[dtype](
                scratch[0].re + scratch[7].re * ya.re + scratch[8].re * yb.re,
                scratch[0].im + scratch[7].im * ya.re + scratch[8].im * yb.re,
            )

            scratch[6] = ComplexScalar[dtype](
                scratch[10].im * ya.im + scratch[9].im * yb.im,
                -scratch[10].re * ya.im - scratch[9].re * yb.im,
            )

            fout1[0] = scratch[5] - scratch[6]
            fout4[0] = scratch[5] + scratch[6]

            scratch[11] = ComplexScalar[dtype](
                scratch[0].re + scratch[7].re * yb.re + scratch[8].re * ya.re,
                scratch[0].im + scratch[7].im * yb.re + scratch[8].im * ya.re,
            )
            scratch[12] = ComplexScalar[dtype](
                -scratch[10].im * yb.im + scratch[9].im * ya.im,
                scratch[10].re * yb.im - scratch[9].re * ya.im,
            )

            fout2[0] = scratch[11] + scratch[12]
            fout3[0] = scratch[11] - scratch[12]

            fout0 = fout0[1:]
            fout1 = fout1[1:]
            fout2 = fout2[1:]
            fout3 = fout3[1:]
            fout4 = fout4[1:]

    fn _bfly_generic(
        self,
        var fout: Span[mut=True, ComplexScalar[dtype]],
        fstride: Int32,
        m: Int32,
        p: Int32,
    ):
        """Generic radix butterfly for any prime factor."""
        var scratch = List[ComplexScalar[dtype]]()
        scratch.resize(Int(p), ComplexScalar[dtype](0, 0))

        for u in range(m):
            var k = u

            # Copy and divide
            for q1 in range(p):
                scratch[q1] = fout[k]
                k += m

            k = u
            for _ in range(p):
                var twidx = Int32(0)
                fout[k] = scratch[0]

                for q in range(1, p):
                    twidx += fstride * k
                    if twidx >= self.nfft:
                        twidx -= self.nfft
                    var t = scratch[q] * self.twiddles[twidx]
                    fout[k] = fout[k] + t

                k += m

    fn _work(
        mut self,
        fout: Span[mut=True, ComplexScalar[dtype]],
        f: Span[ComplexScalar[dtype]],
        fstride: Int32,
        in_stride: Int32,
        factors_offset: Int32,
    ):
        """Recursive FFT work function."""
        var fout_beg = fout
        var p = self.factors[factors_offset + 0]  # radix
        var m = self.factors[factors_offset + 1]  # stage's fft length / p
        var fout_end = fout[Int(p) * Int(m) :]
        var factors_next = factors_offset + 2

        if m == 1:
            # Base case: copy input
            var curr_f = f
            var curr_fout = fout
            while curr_fout != fout_end:
                curr_fout[0] = curr_f[0]
                curr_f = curr_f[Int(fstride) * Int(in_stride) :]
                curr_fout = curr_fout[1:]
        else:
            # Recursive case
            var curr_f = f
            var curr_fout = fout
            while curr_fout != fout_end:
                self._work(
                    curr_fout, curr_f, fstride * Int(p), in_stride, factors_next
                )
                curr_f = curr_f[Int(fstride) * Int(in_stride) :]
                curr_fout = curr_fout[Int(m) :]

        # Recombine with butterfly
        if p == 2:
            self._bfly2(fout_beg, fstride, m)
        elif p == 3:
            self._bfly3(fout_beg, fstride, m)
        elif p == 4:
            self._bfly4(fout_beg, fstride, m)
        elif p == 5:
            self._bfly5(fout_beg, fstride, m)
        else:
            self._bfly_generic(fout_beg, fstride, m, p)

    fn _factor(mut self, n: Int32):
        """Factor n into radix components (prefers 4, 2, 3, 5, then larger primes).
        """
        var n_remaining = n
        var p = Int32(4)
        var floor_sqrt = Int32(sqrt(Float64(n)))
        var idx = 0

        # Factor out powers of 4, powers of 2, then any remaining primes
        while n_remaining > 1:
            while n_remaining % p != 0:
                if p == 4:
                    p = 2
                elif p == 2:
                    p = 3
                else:
                    p += 2

                if p > floor_sqrt:
                    p = n_remaining  # No more factors, use n itself

            n_remaining //= p
            self.factors[idx] = p
            self.factors[idx + 1] = n_remaining
            idx += 2


# Utility functions


fn kiss_fft_next_fast_size(n: Int) -> Int:
    """Find the next FFT size that factors nicely into 2, 3, and 5.

    Args:
        n: Desired minimum FFT size.

    Returns:
        The smallest size >= n that is efficiently factorable.
    """
    var candidate = n
    while True:
        var m = candidate
        while m % 2 == 0:
            m //= 2
        while m % 3 == 0:
            m //= 3
        while m % 5 == 0:
            m //= 5
        if m <= 1:
            return candidate  # Completely factorable
        candidate += 1
