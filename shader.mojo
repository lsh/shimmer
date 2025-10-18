from shader_util import *
from vec import *

from gpu.host import DeviceContext, DeviceBuffer
from gpu import global_idx
from math import ceildiv, cos, sin


fn kernel[shader: Shader](ptr: UnsafePointer[UInt32], uniforms: Uniforms):
    var idx = Int(global_idx.x)
    if idx > Int(uniforms.width * uniforms.height):
        return

    var x = idx % Int(uniforms.width)
    var y = idx // Int(uniforms.width)

    var uv = Vec2(
        Float32(x) / Float32(uniforms.width),
        Float32(y) / Float32(uniforms.height),
    )
    var col = shader.main_image(uv, uniforms)

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
        ctx.enqueue_function_experimental[kernel[shaders.Spheres]](
            buffer,
            uniforms,
            grid_dim=ceildiv(uniforms.width * uniforms.height, 256),
            block_dim=256,
        )
    except e:
        print("Error running shader", e)
