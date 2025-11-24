"""
PortAudio Portable Real-Time Audio Library
Mojo bindings for PortAudio API

Based on PortAudio V19.5.0
Copyright (c) 1999-2002 Ross Bencina and Phil Burk
"""

from sys.ffi import external_call
from ffipointer import FFIPointer

# ===========================
# Version Information
# ===========================


fn Pa_GetVersion() -> Int32:
    """Retrieve the release number of the currently running PortAudio build."""
    return external_call["Pa_GetVersion", Int32]()


fn Pa_GetVersionText() -> FFIPointer[UInt8, mut=False]:
    """Retrieve a textual description of the current PortAudio build."""
    return external_call["Pa_GetVersionText", FFIPointer[UInt8, mut=False]]()


@fieldwise_init
struct PaVersionInfo(Copyable, ImplicitlyCopyable, Movable):
    var versionMajor: Int32
    var versionMinor: Int32
    var versionSubMinor: Int32
    var versionControlRevision: FFIPointer[UInt8, mut=False]
    var versionText: FFIPointer[UInt8, mut=False]


fn Pa_GetVersionInfo() -> FFIPointer[PaVersionInfo, mut=False]:
    """Retrieve version information for the currently running PortAudio build.
    """
    return external_call[
        "Pa_GetVersionInfo", FFIPointer[PaVersionInfo, mut=False]
    ]()


# ===========================
# Error Codes
# ===========================

comptime PaError = Int32

comptime paNoError: Int32 = 0
comptime paNotInitialized: Int32 = -10000
comptime paUnanticipatedHostError: Int32 = -9999
comptime paInvalidChannelCount: Int32 = -9998
comptime paInvalidSampleRate: Int32 = -9997
comptime paInvalidDevice: Int32 = -9996
comptime paInvalidFlag: Int32 = -9995
comptime paSampleFormatNotSupported: Int32 = -9994
comptime paBadIODeviceCombination: Int32 = -9993
comptime paInsufficientMemory: Int32 = -9992
comptime paBufferTooBig: Int32 = -9991
comptime paBufferTooSmall: Int32 = -9990
comptime paNullCallback: Int32 = -9989
comptime paBadStreamPtr: Int32 = -9988
comptime paTimedOut: Int32 = -9987
comptime paInternalError: Int32 = -9986
comptime paDeviceUnavailable: Int32 = -9985
comptime paIncompatibleHostApiSpecificStreamInfo: Int32 = -9984
comptime paStreamIsStopped: Int32 = -9983
comptime paStreamIsNotStopped: Int32 = -9982
comptime paInputOverflowed: Int32 = -9981
comptime paOutputUnderflowed: Int32 = -9980
comptime paHostApiNotFound: Int32 = -9979
comptime paInvalidHostApi: Int32 = -9978
comptime paCanNotReadFromACallbackStream: Int32 = -9977
comptime paCanNotWriteToACallbackStream: Int32 = -9976
comptime paCanNotReadFromAnOutputOnlyStream: Int32 = -9975
comptime paCanNotWriteToAnInputOnlyStream: Int32 = -9974
comptime paIncompatibleStreamHostApi: Int32 = -9973
comptime paBadBufferPtr: Int32 = -9972
comptime paCanNotInitializeRecursively: Int32 = -9971


fn Pa_GetErrorText(errorCode: PaError) -> FFIPointer[UInt8, mut=False]:
    """Translate the supplied PortAudio error code into a human readable message.
    """
    return external_call[
        "Pa_GetErrorText", FFIPointer[UInt8, mut=False], PaError
    ](errorCode)


# ===========================
# Initialization / Termination
# ===========================


fn Pa_Initialize() -> PaError:
    """Library initialization function - call this before using PortAudio."""
    return external_call["Pa_Initialize", PaError]()


fn Pa_Terminate() -> PaError:
    """Library termination function - call this when finished using PortAudio.
    """
    return external_call["Pa_Terminate", PaError]()


# ===========================
# Device and Host API Types
# ===========================

comptime PaDeviceIndex = Int32
comptime paNoDevice: PaDeviceIndex = -1
comptime paUseHostApiSpecificDeviceSpecification: PaDeviceIndex = -2

comptime PaHostApiIndex = Int32


fn Pa_GetHostApiCount() -> PaHostApiIndex:
    """Retrieve the number of available host APIs."""
    return external_call["Pa_GetHostApiCount", PaHostApiIndex]()


fn Pa_GetDefaultHostApi() -> PaHostApiIndex:
    """Retrieve the index of the default host API."""
    return external_call["Pa_GetDefaultHostApi", PaHostApiIndex]()


# Host API Type IDs
comptime paInDevelopment: Int32 = 0
comptime paDirectSound: Int32 = 1
comptime paMME: Int32 = 2
comptime paASIO: Int32 = 3
comptime paSoundManager: Int32 = 4
comptime paCoreAudio: Int32 = 5
comptime paOSS: Int32 = 7
comptime paALSA: Int32 = 8
comptime paAL: Int32 = 9
comptime paBeOS: Int32 = 10
comptime paWDMKS: Int32 = 11
comptime paJACK: Int32 = 12
comptime paWASAPI: Int32 = 13
comptime paAudioScienceHPI: Int32 = 14
comptime paAudioIO: Int32 = 15
comptime paPulseAudio: Int32 = 16
comptime paSndio: Int32 = 17

comptime PaHostApiTypeId = Int32


@fieldwise_init
struct PaHostApiInfo(Copyable, ImplicitlyCopyable, Movable):
    var structVersion: Int32
    var type: PaHostApiTypeId
    var name: FFIPointer[UInt8, mut=False]
    var deviceCount: Int32
    var defaultInputDevice: PaDeviceIndex
    var defaultOutputDevice: PaDeviceIndex


fn Pa_GetHostApiInfo(
    hostApi: PaHostApiIndex,
) -> FFIPointer[PaHostApiInfo, mut=False]:
    """Retrieve a pointer to a structure containing information about a specific host API.
    """
    return external_call[
        "Pa_GetHostApiInfo",
        FFIPointer[PaHostApiInfo, mut=False],
        PaHostApiIndex,
    ](hostApi)


fn Pa_HostApiTypeIdToHostApiIndex(type: PaHostApiTypeId) -> PaHostApiIndex:
    """Convert a static host API unique identifier into a runtime host API index.
    """
    return external_call[
        "Pa_HostApiTypeIdToHostApiIndex", PaHostApiIndex, PaHostApiTypeId
    ](type)


fn Pa_HostApiDeviceIndexToDeviceIndex(
    hostApi: PaHostApiIndex, hostApiDeviceIndex: Int32
) -> PaDeviceIndex:
    """Convert a host-API-specific device index to standard PortAudio device index.
    """
    return external_call[
        "Pa_HostApiDeviceIndexToDeviceIndex",
        PaDeviceIndex,
        PaHostApiIndex,
        Int32,
    ](hostApi, hostApiDeviceIndex)


@fieldwise_init
struct PaHostErrorInfo(Copyable, ImplicitlyCopyable, Movable):
    var hostApiType: PaHostApiTypeId
    var errorCode: Int64
    var errorText: FFIPointer[UInt8, mut=False]


fn Pa_GetLastHostErrorInfo() -> FFIPointer[PaHostErrorInfo, mut=False]:
    """Return information about the last host error encountered."""
    return external_call[
        "Pa_GetLastHostErrorInfo", FFIPointer[PaHostErrorInfo, mut=False]
    ]()


# ===========================
# Device Enumeration
# ===========================


fn Pa_GetDeviceCount() -> PaDeviceIndex:
    """Retrieve the number of available devices."""
    return external_call["Pa_GetDeviceCount", PaDeviceIndex]()


fn Pa_GetDefaultInputDevice() -> PaDeviceIndex:
    """Retrieve the index of the default input device."""
    return external_call["Pa_GetDefaultInputDevice", PaDeviceIndex]()


fn Pa_GetDefaultOutputDevice() -> PaDeviceIndex:
    """Retrieve the index of the default output device."""
    return external_call["Pa_GetDefaultOutputDevice", PaDeviceIndex]()


comptime PaTime = Float64

# Sample Format Flags
comptime PaSampleFormat = UInt64

comptime paFloat32: PaSampleFormat = 0x00000001
comptime paInt32: PaSampleFormat = 0x00000002
comptime paInt24: PaSampleFormat = 0x00000004
comptime paInt16: PaSampleFormat = 0x00000008
comptime paInt8: PaSampleFormat = 0x00000010
comptime paUInt8: PaSampleFormat = 0x00000020
comptime paCustomFormat: PaSampleFormat = 0x00010000
comptime paNonInterleaved: PaSampleFormat = 0x80000000


@fieldwise_init
struct PaDeviceInfo(Copyable, ImplicitlyCopyable, Movable):
    var structVersion: Int32
    var name: FFIPointer[UInt8, mut=False]
    var hostApi: PaHostApiIndex
    var maxInputChannels: Int32
    var maxOutputChannels: Int32
    var defaultLowInputLatency: PaTime
    var defaultLowOutputLatency: PaTime
    var defaultHighInputLatency: PaTime
    var defaultHighOutputLatency: PaTime
    var defaultSampleRate: Float64


fn Pa_GetDeviceInfo(
    device: PaDeviceIndex,
) -> FFIPointer[PaDeviceInfo, mut=False]:
    """Retrieve a pointer to a PaDeviceInfo structure containing information about the specified device.
    """
    return external_call[
        "Pa_GetDeviceInfo", FFIPointer[PaDeviceInfo, mut=False], PaDeviceIndex
    ](device)


# ===========================
# Stream Parameters
# ===========================


@fieldwise_init
struct PaStreamParameters(Copyable, ImplicitlyCopyable, Movable):
    var device: PaDeviceIndex
    var channelCount: Int32
    var sampleFormat: PaSampleFormat
    var suggestedLatency: PaTime
    var hostApiSpecificStreamInfo: FFIPointer[NoneType, mut=False]


comptime paFormatIsSupported: Int32 = 0


fn Pa_IsFormatSupported(
    inputParameters: FFIPointer[PaStreamParameters, mut=False],
    outputParameters: FFIPointer[PaStreamParameters, mut=False],
    sampleRate: Float64,
) -> PaError:
    """Determine whether it would be possible to open a stream with the specified parameters.
    """
    return external_call[
        "Pa_IsFormatSupported",
        PaError,
        FFIPointer[PaStreamParameters, mut=False],
        FFIPointer[PaStreamParameters, mut=False],
        Float64,
    ](inputParameters, outputParameters, sampleRate)


# ===========================
# Stream Types and Functions
# ===========================


@fieldwise_init
struct PaStream(Copyable, ImplicitlyCopyable, Movable):
    pass


comptime paFramesPerBufferUnspecified: UInt64 = 0

# Stream Flags
comptime PaStreamFlags = UInt64

comptime paNoFlag: PaStreamFlags = 0
comptime paClipOff: PaStreamFlags = 0x00000001
comptime paDitherOff: PaStreamFlags = 0x00000002
comptime paNeverDropInput: PaStreamFlags = 0x00000004
comptime paPrimeOutputBuffersUsingStreamCallback: PaStreamFlags = 0x00000008
comptime paPlatformSpecificFlags: PaStreamFlags = 0xFFFF0000


@fieldwise_init
struct PaStreamCallbackTimeInfo(Copyable, ImplicitlyCopyable, Movable):
    var inputBufferAdcTime: PaTime
    var currentTime: PaTime
    var outputBufferDacTime: PaTime


# Stream Callback Flags
comptime PaStreamCallbackFlags = UInt64

comptime paInputUnderflow: PaStreamCallbackFlags = 0x00000001
comptime paInputOverflow: PaStreamCallbackFlags = 0x00000002
comptime paOutputUnderflow: PaStreamCallbackFlags = 0x00000004
comptime paOutputOverflow: PaStreamCallbackFlags = 0x00000008
comptime paPrimingOutput: PaStreamCallbackFlags = 0x00000010

# Stream Callback Result
alias PaStreamCallbackResult = Int32
comptime paContinue: PaStreamCallbackResult = 0
comptime paComplete: PaStreamCallbackResult = 1
comptime paAbort: PaStreamCallbackResult = 2


fn Pa_OpenStream(
    stream: FFIPointer[FFIPointer[PaStream, mut=True], mut=True],
    inputParameters: FFIPointer[PaStreamParameters, mut=False],
    outputParameters: FFIPointer[PaStreamParameters, mut=False],
    sampleRate: Float64,
    framesPerBuffer: UInt,
    streamFlags: PaStreamFlags,
    streamCallback: FFIPointer[NoneType, mut=False],
    userData: FFIPointer[NoneType, mut=True],
) -> PaError:
    """Opens a stream for either input, output or both."""
    return external_call[
        "Pa_OpenStream",
        PaError,
        FFIPointer[FFIPointer[PaStream, mut=True], mut=True],
        FFIPointer[PaStreamParameters, mut=False],
        FFIPointer[PaStreamParameters, mut=False],
        Float64,
        UInt,
        PaStreamFlags,
        FFIPointer[NoneType, mut=False],
        FFIPointer[NoneType, mut=True],
    ](
        stream,
        inputParameters,
        outputParameters,
        sampleRate,
        framesPerBuffer,
        streamFlags,
        streamCallback,
        userData,
    )


fn Pa_OpenDefaultStream(
    stream: FFIPointer[FFIPointer[PaStream, mut=True], mut=True],
    numInputChannels: Int32,
    numOutputChannels: Int32,
    sampleFormat: PaSampleFormat,
    sampleRate: Float64,
    framesPerBuffer: UInt64,
    streamCallback: FFIPointer[NoneType, mut=False],
    userData: FFIPointer[NoneType, mut=True],
) -> PaError:
    """A simplified version of Pa_OpenStream() that opens the default input and/or output devices.
    """
    return external_call[
        "Pa_OpenDefaultStream",
        PaError,
        FFIPointer[FFIPointer[PaStream, mut=True], mut=True],
        Int32,
        Int32,
        PaSampleFormat,
        Float64,
        UInt64,
        FFIPointer[NoneType, mut=False],
        FFIPointer[NoneType, mut=True],
    ](
        stream,
        numInputChannels,
        numOutputChannels,
        sampleFormat,
        sampleRate,
        framesPerBuffer,
        streamCallback,
        userData,
    )


fn Pa_CloseStream(stream: FFIPointer[PaStream, mut=True]) -> PaError:
    """Closes an audio stream."""
    return external_call[
        "Pa_CloseStream", PaError, FFIPointer[PaStream, mut=True]
    ](stream)


fn Pa_SetStreamFinishedCallback(
    stream: FFIPointer[PaStream, mut=True],
    streamFinishedCallback: FFIPointer[NoneType, mut=False],
) -> PaError:
    """Register a stream finished callback function."""
    return external_call[
        "Pa_SetStreamFinishedCallback",
        PaError,
        FFIPointer[PaStream, mut=True],
        FFIPointer[NoneType, mut=False],
    ](stream, streamFinishedCallback)


fn Pa_StartStream(stream: FFIPointer[PaStream, mut=True]) -> PaError:
    """Commences audio processing."""
    return external_call[
        "Pa_StartStream", PaError, FFIPointer[PaStream, mut=True]
    ](stream)


fn Pa_StopStream(stream: FFIPointer[PaStream, mut=True]) -> PaError:
    """Terminates audio processing."""
    return external_call[
        "Pa_StopStream", PaError, FFIPointer[PaStream, mut=True]
    ](stream)


fn Pa_AbortStream(stream: FFIPointer[PaStream, mut=True]) -> PaError:
    """Terminates audio processing promptly."""
    return external_call[
        "Pa_AbortStream", PaError, FFIPointer[PaStream, mut=True]
    ](stream)


fn Pa_IsStreamStopped(stream: FFIPointer[PaStream, mut=False]) -> PaError:
    """Determine whether the stream is stopped."""
    return external_call[
        "Pa_IsStreamStopped", PaError, FFIPointer[PaStream, mut=False]
    ](stream)


fn Pa_IsStreamActive(stream: FFIPointer[PaStream, mut=False]) -> PaError:
    """Determine whether the stream is active."""
    return external_call[
        "Pa_IsStreamActive", PaError, FFIPointer[PaStream, mut=False]
    ](stream)


@fieldwise_init
struct PaStreamInfo(Copyable, ImplicitlyCopyable, Movable):
    var structVersion: Int32
    var inputLatency: PaTime
    var outputLatency: PaTime
    var sampleRate: Float64


fn Pa_GetStreamInfo(
    stream: FFIPointer[PaStream, mut=False],
) -> FFIPointer[PaStreamInfo, mut=False]:
    """Retrieve a pointer to a PaStreamInfo structure containing information about the specified stream.
    """
    return external_call[
        "Pa_GetStreamInfo",
        FFIPointer[PaStreamInfo, mut=False],
        FFIPointer[PaStream, mut=False],
    ](stream)


fn Pa_GetStreamTime(stream: FFIPointer[PaStream, mut=False]) -> PaTime:
    """Returns the current time in seconds for a stream."""
    return external_call[
        "Pa_GetStreamTime", PaTime, FFIPointer[PaStream, mut=False]
    ](stream)


fn Pa_GetStreamCpuLoad(stream: FFIPointer[PaStream, mut=False]) -> Float64:
    """Retrieve CPU usage information for the specified stream."""
    return external_call[
        "Pa_GetStreamCpuLoad", Float64, FFIPointer[PaStream, mut=False]
    ](stream)


fn Pa_ReadStream(
    stream: FFIPointer[PaStream, mut=True],
    buffer: FFIPointer[NoneType, mut=True],
    frames: UInt64,
) -> PaError:
    """Read samples from an input stream."""
    return external_call[
        "Pa_ReadStream",
        PaError,
        FFIPointer[PaStream, mut=True],
        FFIPointer[NoneType, mut=True],
        UInt64,
    ](stream, buffer, frames)


fn Pa_WriteStream(
    stream: FFIPointer[PaStream, mut=True],
    buffer: FFIPointer[NoneType, mut=False],
    frames: UInt64,
) -> PaError:
    """Write samples to an output stream."""
    return external_call[
        "Pa_WriteStream",
        PaError,
        FFIPointer[PaStream, mut=True],
        FFIPointer[NoneType, mut=False],
        UInt64,
    ](stream, buffer, frames)


fn Pa_GetStreamReadAvailable(stream: FFIPointer[PaStream, mut=False]) -> Int:
    """Retrieve the number of frames that can be read from the stream without waiting.
    """
    return external_call[
        "Pa_GetStreamReadAvailable", Int, FFIPointer[PaStream, mut=False]
    ](stream)


fn Pa_GetStreamWriteAvailable(stream: FFIPointer[PaStream, mut=False]) -> Int:
    """Retrieve the number of frames that can be written to the stream without waiting.
    """
    return external_call[
        "Pa_GetStreamWriteAvailable", Int, FFIPointer[PaStream, mut=False]
    ](stream)


# ===========================
# Miscellaneous Utilities
# ===========================


fn Pa_GetSampleSize(format: PaSampleFormat) -> PaError:
    """Retrieve the size of a given sample format in bytes."""
    return external_call["Pa_GetSampleSize", PaError, PaSampleFormat](format)


fn Pa_Sleep(msec: Int) -> None:
    """Put the caller to sleep for at least 'msec' milliseconds."""
    _ = external_call["Pa_Sleep", NoneType, Int](msec)
