from sys.ffi import external_call, c_size_t, DLHandle, RTLD
from sys.info import size_of

# Defining opaque structs for FFI

# fmt: off
struct __CFString: ...
struct __CFDictionary: ...
struct __CFBoolean: ...
struct __CFAllocator: ...
struct __CVBuffer: ...
# fmt: on


# Basic Core Foundation types
alias CFTypeRef = OpaquePointer
alias CFStringRef = UnsafePointer[__CFString]
alias CFDictionaryRef = UnsafePointer[__CFDictionary]
alias CFMutableDictionaryRef = UnsafePointer[__CFDictionary]
alias CFBooleanRef = UnsafePointer[__CFBoolean]
alias CFAllocatorRef = UnsafePointer[__CFAllocator]
alias CFIndex = Int64
alias CVReturn = Int32
alias CVPixelFormatType = UInt32
alias MTLPixelFormat = UInt32

# CVPixelBuffer types


alias CVBufferRef = UnsafePointer[__CVBuffer]
alias CVPixelBufferRef = CVBufferRef
alias CVImageBufferRef = CVBufferRef
alias CVMetalTextureRef = CVImageBufferRef
alias CVOpenGLTextureRef = CVImageBufferRef


# Size structure (from CoreGraphics)
@fieldwise_init
@register_passable("trivial")
struct CGSize(Copyable, Movable):
    var width: Float64
    var height: Float64


# Dictionary callback structures
@fieldwise_init
struct CFDictionaryKeyCallBacks(Copyable, Movable):
    var version: CFIndex
    var retain: fn (CFAllocatorRef, OpaquePointer) -> OpaquePointer
    var release: fn (CFAllocatorRef, OpaquePointer) -> None
    var copyDescription: fn (OpaquePointer) -> CFStringRef
    var equal: fn (OpaquePointer, OpaquePointer) -> Bool
    var hash: fn (OpaquePointer) -> UInt


@fieldwise_init
struct CFDictionaryValueCallBacks(Copyable, Movable):
    var version: CFIndex
    var retain: fn (CFAllocatorRef, OpaquePointer) -> OpaquePointer
    var release: fn (CFAllocatorRef, OpaquePointer) -> None
    var copyDescription: fn (OpaquePointer) -> CFStringRef
    var equal: fn (OpaquePointer, OpaquePointer) -> Bool


fn CVPixelBufferCreate(
    allocator: CFAllocatorRef,
    width: c_size_t,
    height: c_size_t,
    pixelFormatType: CVPixelFormatType,
    pixelBufferAttributes: CFDictionaryRef,
    pixelBufferOut: UnsafePointer[CVPixelBufferRef],
) -> CVReturn:
    return external_call[
        "CVPixelBufferCreate",
        CVReturn,
        CFAllocatorRef,
        c_size_t,
        c_size_t,
        CVPixelFormatType,
        CFDictionaryRef,
        UnsafePointer[CVPixelBufferRef],
    ](
        allocator,
        width,
        height,
        pixelFormatType,
        pixelBufferAttributes,
        pixelBufferOut,
    )


fn CFDictionaryCreate(
    allocator: CFAllocatorRef,
    keys: UnsafePointer[OpaquePointer],
    values: UnsafePointer[OpaquePointer],
    numValues: CFIndex,
    keyCallBacks: UnsafePointer[CFDictionaryKeyCallBacks],
    valueCallBacks: UnsafePointer[CFDictionaryValueCallBacks],
) -> CFDictionaryRef:
    return external_call[
        "CFDictionaryCreate",
        CFDictionaryRef,
        CFAllocatorRef,
        UnsafePointer[OpaquePointer],
        UnsafePointer[OpaquePointer],
        CFIndex,
        UnsafePointer[CFDictionaryKeyCallBacks],
        UnsafePointer[CFDictionaryValueCallBacks],
    ](
        allocator,
        keys,
        values,
        numValues,
        keyCallBacks,
        valueCallBacks,
    )


fn CFDictionarySetValue(
    theDict: CFMutableDictionaryRef,
    key: OpaquePointer,
    value: OpaquePointer,
):
    external_call[
        "CFDictionarySetValue",
        NoneType,
        CFMutableDictionaryRef,
        OpaquePointer,
        OpaquePointer,
    ](theDict, key, value)


fn CFDictionaryCreateMutable(
    allocator: CFAllocatorRef,
    numValues: CFIndex,
    keyCallBacks: UnsafePointer[CFDictionaryKeyCallBacks],
    valueCallBacks: UnsafePointer[CFDictionaryValueCallBacks],
) -> CFDictionaryRef:
    return external_call[
        "CFDictionaryCreateMutable",
        CFDictionaryRef,
        CFAllocatorRef,
        CFIndex,
        UnsafePointer[CFDictionaryKeyCallBacks],
        UnsafePointer[CFDictionaryValueCallBacks],
    ](
        allocator,
        numValues,
        keyCallBacks,
        valueCallBacks,
    )


fn CFRelease(cf: CFTypeRef):
    external_call["CFRelease", NoneType, CFTypeRef](cf)


fn CVOpenGLTextureCacheCreate(
    allocator: CFAllocatorRef,
    cacheAttributes: CFDictionaryRef,
    cglContext: UnsafePointer[PlatformGLContext],
    cglPixelFormat: CGLPixelFormatObj,
    textureAttributes: CFDictionaryRef,
    cacheOut: UnsafePointer[CVOpenGLTextureCacheRef],
) -> CVReturn:
    return external_call[
        "CVOpenGLTextureCacheCreate",
        CVReturn,
        CFAllocatorRef,
        CFDictionaryRef,
        UnsafePointer[PlatformGLContext],
        CGLPixelFormatObj,
        CFDictionaryRef,
        UnsafePointer[CVOpenGLTextureCacheRef],
    ](
        allocator,
        cacheAttributes,
        cglContext,
        cglPixelFormat,
        textureAttributes,
        cacheOut,
    )


# Constants (you'll need to get these values from the actual headers or at runtime)
alias kCFAllocatorDefault: CFAllocatorRef = {}  # alias for nullptr
# extern const CFBooleanRef kCFBooleanTrue;
# extern const CFStringRef kCVPixelBufferOpenGLCompatibilityKey;
# extern const CFStringRef kCVPixelBufferMetalCompatibilityKey;
# extern const CFDictionaryKeyCallBacks kCFTypeDictionaryKeyCallBacks;
# extern const CFDictionaryValueCallBacks kCFTypeDictionaryValueCallBacks;

alias kCVPixelFormatType_1Monochrome = 0x00000001  # 1 bit indexed
alias kCVPixelFormatType_2Indexed = 0x00000002  # 2 bit indexed
alias kCVPixelFormatType_4Indexed = 0x00000004  # 4 bit indexed
alias kCVPixelFormatType_8Indexed = 0x00000008  # 8 bit indexed
alias kCVPixelFormatType_1IndexedGray_WhiteIsZero = 0x00000021  # 1 bit indexed gray, white is zero
alias kCVPixelFormatType_2IndexedGray_WhiteIsZero = 0x00000022  # 2 bit indexed gray, white is zero
alias kCVPixelFormatType_4IndexedGray_WhiteIsZero = 0x00000024  # 4 bit indexed gray, white is zero
alias kCVPixelFormatType_8IndexedGray_WhiteIsZero = 0x00000028  # 8 bit indexed gray, white is zero
alias kCVPixelFormatType_16BE555 = 0x00000010  # 16 bit BE RGB 555
alias kCVPixelFormatType_16LE555 = 0x4C353535  # 16 bit LE RGB 555
alias kCVPixelFormatType_16LE5551 = 0x35353531  # 16 bit LE RGB 5551
alias kCVPixelFormatType_16BE565 = 0x42353635  # 16 bit BE RGB 565
alias kCVPixelFormatType_16LE565 = 0x4C353635  # 16 bit LE RGB 565
alias kCVPixelFormatType_24RGB = 0x00000018  # 24 bit RGB
alias kCVPixelFormatType_24BGR = 0x32344247  # 24 bit BGR
alias kCVPixelFormatType_32ARGB = 0x00000020  # 32 bit ARGB
alias kCVPixelFormatType_32BGRA = 0x42475241  # 32 bit BGRA
alias kCVPixelFormatType_32ABGR = 0x41424752  # 32 bit ABGR
alias kCVPixelFormatType_32RGBA = 0x52474241  # 32 bit RGBA
alias kCVPixelFormatType_64ARGB = 0x62363461  # 64 bit ARGB, 16-bit big-endian samples
alias kCVPixelFormatType_64RGBALE = 0x6C363472  # 64 bit RGBA, 16-bit little-endian full-range (0-65535) samples
alias kCVPixelFormatType_48RGB = 0x62343872  # 48 bit RGB, 16-bit big-endian samples
alias kCVPixelFormatType_32AlphaGray = 0x62333261  # 32 bit AlphaGray, 16-bit big-endian samples, black is zero
alias kCVPixelFormatType_16Gray = 0x62313667  # 16 bit Grayscale, 16-bit big-endian samples, black is zero
alias kCVPixelFormatType_30RGB = 0x5231306B  # 30 bit RGB, 10-bit big-endian samples, 2 unused padding bits (at least significant end).
alias kCVPixelFormatType_30RGB_r210 = 0x72323130  # 30 bit RGB, 10-bit big-endian samples, 2 unused padding bits (at most significant end), video-range (64-940).
alias kCVPixelFormatType_422YpCbCr8 = 0x32767579  # Component Y'CbCr 8-bit 4:2:2, ordered Cb Y'0 Cr Y'1
alias kCVPixelFormatType_4444YpCbCrA8 = 0x76343038  # Component Y'CbCrA 8-bit 4:4:4:4, ordered Cb Y' Cr A
alias kCVPixelFormatType_4444YpCbCrA8R = 0x72343038  # Component Y'CbCrA 8-bit 4:4:4:4, rendering format. full range alpha, zero biased YUV, ordered A Y' Cb Cr
alias kCVPixelFormatType_4444AYpCbCr8 = 0x79343038  # Component Y'CbCrA 8-bit 4:4:4:4, ordered A Y' Cb Cr, full range alpha, video range Y'CbCr.
alias kCVPixelFormatType_4444AYpCbCr16 = 0x79343136  # Component Y'CbCrA 16-bit 4:4:4:4, ordered A Y' Cb Cr, full range alpha, video range Y'CbCr, 16-bit little-endian samples.
alias kCVPixelFormatType_4444AYpCbCrFloat = 0x7234666C  # Component AY'CbCr single precision floating-point 4:4:4:4
alias kCVPixelFormatType_444YpCbCr8 = 0x76333038  # Component Y'CbCr 8-bit 4:4:4, ordered Cr Y' Cb, video range Y'CbCr
alias kCVPixelFormatType_422YpCbCr16 = 0x76323136  # Component Y'CbCr 10,12,14,16-bit 4:2:2
alias kCVPixelFormatType_422YpCbCr10 = 0x76323130  # Component Y'CbCr 10-bit 4:2:2
alias kCVPixelFormatType_444YpCbCr10 = 0x76343130  # Component Y'CbCr 10-bit 4:4:4
alias kCVPixelFormatType_420YpCbCr8Planar = 0x79343230  # Planar Component Y'CbCr 8-bit 4:2:0.  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrPlanar struct
alias kCVPixelFormatType_420YpCbCr8PlanarFullRange = 0x66343230  # Planar Component Y'CbCr 8-bit 4:2:0, full range.  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrPlanar struct
alias kCVPixelFormatType_422YpCbCr_4A_8BiPlanar = 0x61327679  # First plane: Video-range Component Y'CbCr 8-bit 4:2:2, ordered Cb Y'0 Cr Y'1; second plane: alpha 8-bit 0-255
alias kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange = 0x34323076  # Bi-Planar Component Y'CbCr 8-bit 4:2:0, video-range (luma=[16,235] chroma=[16,240]).  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct
alias kCVPixelFormatType_420YpCbCr8BiPlanarFullRange = 0x34323066  # Bi-Planar Component Y'CbCr 8-bit 4:2:0, full-range (luma=[0,255] chroma=[1,255]).  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct
alias kCVPixelFormatType_422YpCbCr8BiPlanarVideoRange = 0x34323276  # Bi-Planar Component Y'CbCr 8-bit 4:2:2, video-range (luma=[16,235] chroma=[16,240]).  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct
alias kCVPixelFormatType_422YpCbCr8BiPlanarFullRange = 0x34323266  # Bi-Planar Component Y'CbCr 8-bit 4:2:2, full-range (luma=[0,255] chroma=[1,255]).  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct
alias kCVPixelFormatType_444YpCbCr8BiPlanarVideoRange = 0x34343476  # Bi-Planar Component Y'CbCr 8-bit 4:4:4, video-range (luma=[16,235] chroma=[16,240]).  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct
alias kCVPixelFormatType_444YpCbCr8BiPlanarFullRange = 0x34343466  # Bi-Planar Component Y'CbCr 8-bit 4:4:4, full-range (luma=[0,255] chroma=[1,255]).  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct
alias kCVPixelFormatType_422YpCbCr8_yuvs = 0x79757673  # Component Y'CbCr 8-bit 4:2:2, ordered Y'0 Cb Y'1 Cr
alias kCVPixelFormatType_422YpCbCr8FullRange = 0x79757666  # Component Y'CbCr 8-bit 4:2:2, full range, ordered Y'0 Cb Y'1 Cr
alias kCVPixelFormatType_OneComponent8 = 0x4C303038  # 8 bit one component, black is zero
alias kCVPixelFormatType_TwoComponent8 = 0x32433038  # 8 bit two component, black is zero
alias kCVPixelFormatType_30RGBLEPackedWideGamut = 0x77333072  # little-endian RGB101010, 2 MSB are ignored, wide-gamut (384-895)
alias kCVPixelFormatType_ARGB2101010LEPacked = 0x6C313072  # little-endian ARGB2101010 full-range ARGB
alias kCVPixelFormatType_40ARGBLEWideGamut = 0x77343061  # little-endian ARGB10101010, each 10 bits in the MSBs of 16bits, wide-gamut (384-895, including alpha)
alias kCVPixelFormatType_40ARGBLEWideGamutPremultiplied = 0x7734306D  # little-endian ARGB10101010, each 10 bits in the MSBs of 16bits, wide-gamut (384-895, including alpha). Alpha premultiplied
alias kCVPixelFormatType_OneComponent10 = 0x4C303130  # 10 bit little-endian one component, stored as 10 MSBs of 16 bits, black is zero
alias kCVPixelFormatType_OneComponent12 = 0x4C303132  # 12 bit little-endian one component, stored as 12 MSBs of 16 bits, black is zero
alias kCVPixelFormatType_OneComponent16 = 0x4C303136  # 16 bit little-endian one component, black is zero
alias kCVPixelFormatType_TwoComponent16 = 0x32433136  # 16 bit little-endian two component, black is zero
alias kCVPixelFormatType_OneComponent16Half = 0x4C303068  # 16 bit one component IEEE half-precision float, 16-bit little-endian samples
alias kCVPixelFormatType_OneComponent32Float = 0x4C303066  # 32 bit one component IEEE float, 32-bit little-endian samples
alias kCVPixelFormatType_TwoComponent16Half = 0x32433068  # 16 bit two component IEEE half-precision float, 16-bit little-endian samples
alias kCVPixelFormatType_TwoComponent32Float = 0x32433066  # 32 bit two component IEEE float, 32-bit little-endian samples
alias kCVPixelFormatType_64RGBAHalf = 0x52476841  # 64 bit RGBA IEEE half-precision float, 16-bit little-endian samples
alias kCVPixelFormatType_128RGBAFloat = 0x52476641  # 128 bit RGBA IEEE float, 32-bit little-endian samples
alias kCVPixelFormatType_14Bayer_GRBG = 0x67726234  # Bayer 14-bit Little-Endian, packed in 16-bits, ordered G R G R... alternating with B G B G...
alias kCVPixelFormatType_14Bayer_RGGB = 0x72676734  # Bayer 14-bit Little-Endian, packed in 16-bits, ordered R G R G... alternating with G B G B...
alias kCVPixelFormatType_14Bayer_BGGR = 0x62676734  # Bayer 14-bit Little-Endian, packed in 16-bits, ordered B G B G... alternating with G R G R...
alias kCVPixelFormatType_14Bayer_GBRG = 0x67627234  # Bayer 14-bit Little-Endian, packed in 16-bits, ordered G B G B... alternating with R G R G...
alias kCVPixelFormatType_DisparityFloat16 = 0x68646973  # IEEE754-2008 binary16 (half float), describing the normalized shift when comparing two images. Units are 1/meters: ( pixelShift / (pixelFocalLength * baselineInMeters) )
alias kCVPixelFormatType_DisparityFloat32 = 0x66646973  # IEEE754-2008 binary32 float, describing the normalized shift when comparing two images. Units are 1/meters: ( pixelShift / (pixelFocalLength * baselineInMeters) )
alias kCVPixelFormatType_DepthFloat16 = 0x68646570  # IEEE754-2008 binary16 (half float), describing the depth (distance to an object) in meters
alias kCVPixelFormatType_DepthFloat32 = 0x66646570  # IEEE754-2008 binary32 float, describing the depth (distance to an object) in meters
alias kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange = 0x78343230  # 2 plane YCbCr10 4:2:0, each 10 bits in the MSBs of 16bits, video-range (luma=[64,940] chroma=[64,960])
alias kCVPixelFormatType_422YpCbCr10BiPlanarVideoRange = 0x78343232  # 2 plane YCbCr10 4:2:2, each 10 bits in the MSBs of 16bits, video-range (luma=[64,940] chroma=[64,960])
alias kCVPixelFormatType_444YpCbCr10BiPlanarVideoRange = 0x78343434  # 2 plane YCbCr10 4:4:4, each 10 bits in the MSBs of 16bits, video-range (luma=[64,940] chroma=[64,960])
alias kCVPixelFormatType_420YpCbCr10BiPlanarFullRange = 0x78663230  # 2 plane YCbCr10 4:2:0, each 10 bits in the MSBs of 16bits, full-range (Y range 0-1023)
alias kCVPixelFormatType_422YpCbCr10BiPlanarFullRange = 0x78663232  # 2 plane YCbCr10 4:2:2, each 10 bits in the MSBs of 16bits, full-range (Y range 0-1023)
alias kCVPixelFormatType_444YpCbCr10BiPlanarFullRange = 0x78663434  # 2 plane YCbCr10 4:4:4, each 10 bits in the MSBs of 16bits, full-range (Y range 0-1023)
alias kCVPixelFormatType_420YpCbCr8VideoRange_8A_TriPlanar = 0x76306138  # first and second planes as per 420YpCbCr8BiPlanarVideoRange (420v), alpha 8 bits in third plane full-range.  No CVPlanarPixelBufferInfo struct.
alias kCVPixelFormatType_16VersatileBayer = 0x62703136  # Single plane Bayer 16-bit little-endian sensor element ("sensel") samples from full-size decoding of ProRes RAW images; Bayer pattern (sensel ordering) and other raw conversion information is described via buffer attachments
alias kCVPixelFormatType_64RGBA_DownscaledProResRAW = 0x62703634  # Single plane 64-bit RGBA (16-bit little-endian samples) from downscaled decoding of ProRes RAW images; components--which may not be co-sited with one another--are sensel values and require raw conversion, information for which is described via buffer attachments
alias kCVPixelFormatType_422YpCbCr16BiPlanarVideoRange = 0x73763232  # 2 plane YCbCr16 4:2:2, video-range (luma=[4096,60160] chroma=[4096,61440])
alias kCVPixelFormatType_444YpCbCr16BiPlanarVideoRange = 0x73763434  # 2 plane YCbCr16 4:4:4, video-range (luma=[4096,60160] chroma=[4096,61440])
alias kCVPixelFormatType_444YpCbCr16VideoRange_16A_TriPlanar = 0x73346173  # 3 plane video-range YCbCr16 4:4:4 with 16-bit full-range alpha (luma=[4096,60160] chroma=[4096,61440] alpha=[0,65535]).  No CVPlanarPixelBufferInfo struct.

alias GL_RGBA = 0x1908
alias GL_BGRA = 0x80E1
alias GL_BGRA_EXT = 0x80E1
alias GL_UNSIGNED_INT_8_8_8_8_REV = 0x8367
alias GL_RGB10_A2 = 0x8059
alias GL_UNSIGNED_INT_2_10_10_10_REV = 0x8368
alias GL_SRGB8_ALPHA8 = 0x8C43
alias GL_HALF_FLOAT = 0x140B

alias MTLPixelFormatBGRA8Unorm = 0x50
alias MTLPixelFormatBGR10A2Unorm = 0x5E
alias MTLPixelFormatBGRA8Unorm_sRGB = 0x51
alias MTLPixelFormatRGBA16Float = 0x73


struct PlatformGLContext:
    ...


struct __CVMetalTextureCache:
    ...


alias CVMetalTextureCacheRef = UnsafePointer[__CVMetalTextureCache]


struct _CGLPixelFormat:
    ...


alias CGLPixelFormatObj = UnsafePointer[_CGLPixelFormat]


struct __CVOpenGLTextureCache:
    ...


alias CVOpenGLTextureCacheRef = UnsafePointer[__CVOpenGLTextureCache]


struct _CGLContextObj:
    ...


alias CGLContextObj = UnsafePointer[_CGLContextObj]


fn cgl_get_current_context() -> CGLContextObj:
    return external_call["CGLGetCurrentContext", CGLContextObj]()


fn nsgl_context_get_cgl_context(
    nsgl_context: OpaquePointer,
) raises -> CGLContextObj:
    """Get the CGLContextObj from an NSOpenGLContext.

    This calls the Objective-C method [NSOpenGLContext CGLContextObj]
    """
    # In Objective-C, this would be: [nsgl_context CGLContextObj]

    var objc = DLHandle("libobjc.dylib", RTLD.LAZY)
    return objc.get_function[
        fn (OpaquePointer, OpaquePointer) -> CGLContextObj
    ]("objc_msgSend")(nsgl_context, get_selector("CGLContextObj"))


fn get_selector(name: StringLiteral) -> OpaquePointer:
    """Get an Objective-C selector for the given method name."""
    return external_call[
        "sel_registerName", OpaquePointer, UnsafePointer[Int8]
    ](name.unsafe_cstr_ptr())


fn cgl_get_pixel_format(
    ctx: UnsafePointer[PlatformGLContext],
) -> CGLPixelFormatObj:
    return external_call[
        "CGLGetPixelFormat", CGLPixelFormatObj, UnsafePointer[PlatformGLContext]
    ](ctx)


fn CVOpenGLTextureCacheCreateTextureFromImage(
    allocator: CFAllocatorRef,
    textureCache: CVOpenGLTextureCacheRef,
    sourceImage: CVImageBufferRef,
    attributes: CFDictionaryRef,
    textureOut: UnsafePointer[CVOpenGLTextureRef],
) -> CVReturn:
    return external_call[
        "CVOpenGLTextureCacheCreateTextureFromImage",
        CVReturn,
        CFAllocatorRef,
        CVOpenGLTextureCacheRef,
        CVImageBufferRef,
        CFDictionaryRef,
        UnsafePointer[CVOpenGLTextureRef],
    ](allocator, textureCache, sourceImage, attributes, textureOut)


fn CVOpenGLTextureGetName(image: CVOpenGLTextureRef) -> UInt32:
    return external_call["CVOpenGLTextureGetName", UInt32, CVOpenGLTextureRef](
        image
    )


fn CVOpenGLTextureGetTarget(image: CVOpenGLTextureRef) -> UInt32:
    return external_call[
        "CVOpenGLTextureGetTarget", UInt32, CVOpenGLTextureRef
    ](image)


fn CVMetalTextureCacheCreate(
    allocator: CFAllocatorRef,
    cacheAttributes: CFDictionaryRef,
    metalDevice: OpaquePointer,
    textureAttributes: CFDictionaryRef,
    cacheOut: UnsafePointer[CVMetalTextureCacheRef],
) -> CVReturn:
    return external_call[
        "CVMetalTextureCacheCreate",
        CVReturn,
        CFAllocatorRef,
        CFDictionaryRef,
        OpaquePointer,
        CFDictionaryRef,
        UnsafePointer[CVMetalTextureCacheRef],
    ](
        allocator,
        cacheAttributes,
        metalDevice,
        textureAttributes,
        cacheOut,
    )


fn CVMetalTextureCacheCreateTextureFromImage(
    allocator: CFAllocatorRef,
    textureCache: CVMetalTextureCacheRef,
    sourceImage: CVImageBufferRef,
    textureAttributes: CFDictionaryRef,
    pixelFormat: MTLPixelFormat,
    width: c_size_t,
    height: c_size_t,
    planeIndex: c_size_t,
    textureOut: UnsafePointer[CVMetalTextureRef],
) -> CVReturn:
    return external_call[
        "CVMetalTextureCacheCreateTextureFromImage",
        CVReturn,
        CFAllocatorRef,
        CVMetalTextureCacheRef,
        CVImageBufferRef,
        CFDictionaryRef,
        MTLPixelFormat,  # Use MTLPixelFormat instead of UInt32
        UInt,  # Use UInt for size_t on macOS
        UInt,  # Use UInt for size_t on macOS
        UInt,  # Use UInt for size_t on macOS
        UnsafePointer[CVMetalTextureRef],
    ](
        allocator,
        textureCache,
        sourceImage,
        textureAttributes,
        pixelFormat,
        width,
        height,
        planeIndex,
        textureOut,
    )


fn CVMetalTextureGetTexture(image: CVMetalTextureRef) -> OpaquePointer:
    return external_call[
        "CVMetalTextureGetTexture", OpaquePointer, CVMetalTextureRef
    ](image)


fn CVPixelBufferGetIOSurface(pixelBuffer: CVPixelBufferRef) -> OpaquePointer:
    """Get the IOSurface backing of a pixel buffer."""
    return external_call[
        "CVPixelBufferGetIOSurface", OpaquePointer, CVPixelBufferRef
    ](pixelBuffer)


struct AAPLOpenGLMetalInteropTexture:
    var metal_device: OpaquePointer
    var metal_texture: OpaquePointer
    var gl_context: UnsafePointer[PlatformGLContext]
    var gl_texture: UInt32
    var gl_texture_target: UInt32
    var size: CGSize

    var _format_info: Optional[AAPLTextureFormatInfo]
    var _cv_pixel_buffer: CVPixelBufferRef
    var _cv_mtl_texture: CVMetalTextureRef

    var _cvgl_texture_cache: CVOpenGLTextureCacheRef
    var _cvgl_texture: CVOpenGLTextureRef
    var _cgl_pixel_format: CGLPixelFormatObj
    var _cvmtl_texture_cache: CVMetalTextureCacheRef

    fn __init__(
        out self,
        mtl_device: OpaquePointer,
        gl_context: OpaquePointer,
        mtl_pixel_format: UInt32,
        size: CGSize,
    ) raises:
        self.metal_device = mtl_device
        self.gl_context = gl_context.bitcast[PlatformGLContext]()
        self.gl_texture = 0
        self.gl_texture_target = 0
        self.metal_texture = {}
        self._format_info = metal_pixel_format_to_texture_format_info(
            mtl_pixel_format
        )

        self.size = size
        self._cgl_pixel_format = cgl_get_pixel_format(self.gl_context)
        self._cv_pixel_buffer = {}
        self._cv_mtl_texture = {}
        self._cvgl_texture_cache = {}
        self._cvgl_texture = {}
        self._cvmtl_texture_cache = {}

        var cf = DLHandle(
            "/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation",
            RTLD.LAZY | RTLD.GLOBAL,
        )
        var cv = DLHandle(
            "/System/Library/Frameworks/CoreVideo.framework/CoreVideo",
            RTLD.LAZY | RTLD.GLOBAL,
        )

        var kCFTypeDictionaryKeyCallBacks = cf.get_symbol[
            CFDictionaryKeyCallBacks
        ]("kCFTypeDictionaryKeyCallBacks")
        var kCFTypeDictionaryValueCallBacks = cf.get_symbol[
            CFDictionaryValueCallBacks
        ]("kCFTypeDictionaryValueCallBacks")

        var cv_buffer_properties = CFDictionaryCreateMutable(
            kCFAllocatorDefault,
            2,
            kCFTypeDictionaryKeyCallBacks,
            kCFTypeDictionaryValueCallBacks,
        )

        var true_value = cf.get_symbol[CFBooleanRef]("kCFBooleanTrue")[]

        var k_cv_pixel_buffer_open_gl_compatibility_key = cv.get_symbol[
            CFStringRef
        ]("kCVPixelBufferOpenGLCompatibilityKey")[]
        var k_cv_pixel_buffer_metal_compatibility_key = cv.get_symbol[
            CFStringRef
        ]("kCVPixelBufferMetalCompatibilityKey")[]
        var k_cv_pixel_buffer_io_surface_properties_key = cv.get_symbol[
            CFStringRef
        ]("kCVPixelBufferIOSurfacePropertiesKey")[]

        CFDictionarySetValue(
            cv_buffer_properties,
            k_cv_pixel_buffer_open_gl_compatibility_key.bitcast[NoneType](),
            true_value.bitcast[NoneType](),
        )
        CFDictionarySetValue(
            cv_buffer_properties,
            k_cv_pixel_buffer_metal_compatibility_key.bitcast[NoneType](),
            true_value.bitcast[NoneType](),
        )

        var io_surface_props = CFDictionaryCreateMutable(
            kCFAllocatorDefault,
            0,
            kCFTypeDictionaryKeyCallBacks,
            kCFTypeDictionaryValueCallBacks,
        )
        CFDictionarySetValue(
            cv_buffer_properties,
            k_cv_pixel_buffer_io_surface_properties_key.bitcast[NoneType](),
            io_surface_props.bitcast[NoneType](),
        )
        CFRelease(io_surface_props.bitcast[NoneType]())

        var buffer_width = c_size_t(Int(size.width))
        var buffer_height = c_size_t(Int(size.height))

        var cvret = CVPixelBufferCreate(
            kCFAllocatorDefault,
            buffer_width,
            buffer_height,
            self._format_info[].cv_pixel_format,
            cv_buffer_properties,
            UnsafePointer(to=self._cv_pixel_buffer),
        )

        CFRelease(cv_buffer_properties.bitcast[NoneType]())

        debug_assert(cvret == 0, "Failed to create CVPixelBuffer")

        self.create_gl_texture()
        self.create_metal_texture()

    fn create_gl_texture(mut self) raises:
        var cvret = CVOpenGLTextureCacheCreate(
            kCFAllocatorDefault,
            CFDictionaryRef(),
            self.gl_context,
            self._cgl_pixel_format,
            CFDictionaryRef(),
            UnsafePointer(to=self._cvgl_texture_cache),
        )

        debug_assert(cvret == 0, "Failed to create OpenGL Texture Cache")

        cvret = CVOpenGLTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            self._cvgl_texture_cache,
            self._cv_pixel_buffer,
            CFDictionaryRef(),
            UnsafePointer(to=self._cvgl_texture),
        )

        debug_assert(cvret == 0, "Failed to create OpenGL Texture From Image")

        self.gl_texture = CVOpenGLTextureGetName(self._cvgl_texture)
        self.gl_texture_target = CVOpenGLTextureGetTarget(self._cvgl_texture)

    fn create_metal_texture(mut self) raises:
        var cvret = CVMetalTextureCacheCreate(
            kCFAllocatorDefault,
            CFDictionaryRef(),
            self.metal_device,
            CFDictionaryRef(),
            UnsafePointer(to=self._cvmtl_texture_cache),
        )

        debug_assert(cvret == 0, "Failed to create Metal texture cache")

        var width = UInt(Int(self.size.width))
        var height = UInt(Int(self.size.height))
        var plane_index = UInt(0)

        cvret = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            self._cvmtl_texture_cache,
            self._cv_pixel_buffer,
            CFDictionaryRef(),
            self._format_info[].mtl_format,
            width,
            height,
            plane_index,
            UnsafePointer(to=self._cv_mtl_texture),
        )

        debug_assert(
            cvret == 0, "Failed to create CoreVideo Metal texture from image"
        )

        self.metal_texture = CVMetalTextureGetTexture(self._cv_mtl_texture)

        debug_assert(
            self.metal_texture,
            "Failed to create Metal texture CoreVideo Metal Texture",
        )


@fieldwise_init
struct AAPLTextureFormatInfo(Copyable, Movable):
    var cv_pixel_format: CVPixelFormatType
    var mtl_format: MTLPixelFormat
    var gl_internal_format: UInt32
    var gl_format: UInt32
    var gl_type: UInt32


# Table of equivalent formats across CoreVideo, Metal, and OpenGL
alias AAPLInteropFormatTable = InlineArray[AAPLTextureFormatInfo, 4](
    # Core Video Pixel Format,Metal Pixel Format, GL internalformat, GL format, GL type
    {
        kCVPixelFormatType_32BGRA,
        MTLPixelFormatBGRA8Unorm,
        GL_RGBA,
        GL_BGRA_EXT,
        GL_UNSIGNED_INT_8_8_8_8_REV,
    },
    {
        kCVPixelFormatType_ARGB2101010LEPacked,
        MTLPixelFormatBGR10A2Unorm,
        GL_RGB10_A2,
        GL_BGRA,
        GL_UNSIGNED_INT_2_10_10_10_REV,
    },
    {
        kCVPixelFormatType_32BGRA,
        MTLPixelFormatBGRA8Unorm_sRGB,
        GL_SRGB8_ALPHA8,
        GL_BGRA,
        GL_UNSIGNED_INT_8_8_8_8_REV,
    },
    {
        kCVPixelFormatType_64RGBAHalf,
        MTLPixelFormatRGBA16Float,
        GL_RGBA,
        GL_RGBA,
        GL_HALF_FLOAT,
    },
)


fn metal_pixel_format_to_texture_format_info(
    pixel_format: UInt32,
) -> Optional[AAPLTextureFormatInfo]:
    for i in range(len(AAPLInteropFormatTable)):
        if pixel_format == AAPLInteropFormatTable[i].mtl_format:
            return AAPLInteropFormatTable[i].copy()
    return None
