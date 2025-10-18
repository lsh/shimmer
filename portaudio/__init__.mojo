"""
PortAudio Portable Real-Time Audio Library
Mojo bindings for PortAudio API

Based on PortAudio V19.5.0
Copyright (c) 1999-2002 Ross Bencina and Phil Burk
"""

from sys.ffi import external_call

# ===========================
# Version Information
# ===========================


fn Pa_GetVersion() -> Int32:
    """Retrieve the release number of the currently running PortAudio build."""
    return external_call["Pa_GetVersion", Int32]()


fn Pa_GetVersionText() -> UnsafePointer[UInt8]:
    """Retrieve a textual description of the current PortAudio build."""
    return external_call["Pa_GetVersionText", UnsafePointer[UInt8]]()


@fieldwise_init
struct PaVersionInfo:
    var versionMajor: Int32
    var versionMinor: Int32
    var versionSubMinor: Int32
    var versionControlRevision: UnsafePointer[UInt8]
    var versionText: UnsafePointer[UInt8]


fn Pa_GetVersionInfo() -> UnsafePointer[PaVersionInfo]:
    """Retrieve version information for the currently running PortAudio build.
    """
    return external_call["Pa_GetVersionInfo", UnsafePointer[PaVersionInfo]]()


# ===========================
# Error Codes
# ===========================

alias PaError = Int32

alias paNoError: Int32 = 0
alias paNotInitialized: Int32 = -10000
alias paUnanticipatedHostError: Int32 = -9999
alias paInvalidChannelCount: Int32 = -9998
alias paInvalidSampleRate: Int32 = -9997
alias paInvalidDevice: Int32 = -9996
alias paInvalidFlag: Int32 = -9995
alias paSampleFormatNotSupported: Int32 = -9994
alias paBadIODeviceCombination: Int32 = -9993
alias paInsufficientMemory: Int32 = -9992
alias paBufferTooBig: Int32 = -9991
alias paBufferTooSmall: Int32 = -9990
alias paNullCallback: Int32 = -9989
alias paBadStreamPtr: Int32 = -9988
alias paTimedOut: Int32 = -9987
alias paInternalError: Int32 = -9986
alias paDeviceUnavailable: Int32 = -9985
alias paIncompatibleHostApiSpecificStreamInfo: Int32 = -9984
alias paStreamIsStopped: Int32 = -9983
alias paStreamIsNotStopped: Int32 = -9982
alias paInputOverflowed: Int32 = -9981
alias paOutputUnderflowed: Int32 = -9980
alias paHostApiNotFound: Int32 = -9979
alias paInvalidHostApi: Int32 = -9978
alias paCanNotReadFromACallbackStream: Int32 = -9977
alias paCanNotWriteToACallbackStream: Int32 = -9976
alias paCanNotReadFromAnOutputOnlyStream: Int32 = -9975
alias paCanNotWriteToAnInputOnlyStream: Int32 = -9974
alias paIncompatibleStreamHostApi: Int32 = -9973
alias paBadBufferPtr: Int32 = -9972
alias paCanNotInitializeRecursively: Int32 = -9971


fn Pa_GetErrorText(errorCode: PaError) -> UnsafePointer[UInt8]:
    """Translate the supplied PortAudio error code into a human readable message.
    """
    return external_call["Pa_GetErrorText", UnsafePointer[UInt8], PaError](
        errorCode
    )


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

alias PaDeviceIndex = Int32
alias paNoDevice: PaDeviceIndex = -1
alias paUseHostApiSpecificDeviceSpecification: PaDeviceIndex = -2

alias PaHostApiIndex = Int32


fn Pa_GetHostApiCount() -> PaHostApiIndex:
    """Retrieve the number of available host APIs."""
    return external_call["Pa_GetHostApiCount", PaHostApiIndex]()


fn Pa_GetDefaultHostApi() -> PaHostApiIndex:
    """Retrieve the index of the default host API."""
    return external_call["Pa_GetDefaultHostApi", PaHostApiIndex]()


# Host API Type IDs
alias paInDevelopment: Int32 = 0
alias paDirectSound: Int32 = 1
alias paMME: Int32 = 2
alias paASIO: Int32 = 3
alias paSoundManager: Int32 = 4
alias paCoreAudio: Int32 = 5
alias paOSS: Int32 = 7
alias paALSA: Int32 = 8
alias paAL: Int32 = 9
alias paBeOS: Int32 = 10
alias paWDMKS: Int32 = 11
alias paJACK: Int32 = 12
alias paWASAPI: Int32 = 13
alias paAudioScienceHPI: Int32 = 14
alias paAudioIO: Int32 = 15
alias paPulseAudio: Int32 = 16
alias paSndio: Int32 = 17

alias PaHostApiTypeId = Int32


@fieldwise_init
struct PaHostApiInfo:
    var structVersion: Int32
    var type: PaHostApiTypeId
    var name: UnsafePointer[UInt8]
    var deviceCount: Int32
    var defaultInputDevice: PaDeviceIndex
    var defaultOutputDevice: PaDeviceIndex


fn Pa_GetHostApiInfo(hostApi: PaHostApiIndex) -> UnsafePointer[PaHostApiInfo]:
    """Retrieve a pointer to a structure containing information about a specific host API.
    """
    return external_call[
        "Pa_GetHostApiInfo", UnsafePointer[PaHostApiInfo], PaHostApiIndex
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
struct PaHostErrorInfo:
    var hostApiType: PaHostApiTypeId
    var errorCode: Int
    var errorText: UnsafePointer[UInt8]


fn Pa_GetLastHostErrorInfo() -> UnsafePointer[PaHostErrorInfo]:
    """Return information about the last host error encountered."""
    return external_call[
        "Pa_GetLastHostErrorInfo", UnsafePointer[PaHostErrorInfo]
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


alias PaTime = Float64

# Sample Format Flags
alias PaSampleFormat = UInt

alias paFloat32: PaSampleFormat = 0x00000001
alias paInt32: PaSampleFormat = 0x00000002
alias paInt24: PaSampleFormat = 0x00000004
alias paInt16: PaSampleFormat = 0x00000008
alias paInt8: PaSampleFormat = 0x00000010
alias paUInt8: PaSampleFormat = 0x00000020
alias paCustomFormat: PaSampleFormat = 0x00010000
alias paNonInterleaved: PaSampleFormat = 0x80000000


@fieldwise_init
struct PaDeviceInfo:
    var structVersion: Int32
    var name: UnsafePointer[UInt8]
    var hostApi: PaHostApiIndex
    var maxInputChannels: Int32
    var maxOutputChannels: Int32
    var defaultLowInputLatency: PaTime
    var defaultLowOutputLatency: PaTime
    var defaultHighInputLatency: PaTime
    var defaultHighOutputLatency: PaTime
    var defaultSampleRate: Float64


fn Pa_GetDeviceInfo(device: PaDeviceIndex) -> UnsafePointer[PaDeviceInfo]:
    """Retrieve a pointer to a PaDeviceInfo structure containing information about the specified device.
    """
    return external_call[
        "Pa_GetDeviceInfo", UnsafePointer[PaDeviceInfo], PaDeviceIndex
    ](device)


# ===========================
# Stream Parameters
# ===========================


@fieldwise_init
struct PaStreamParameters:
    var device: PaDeviceIndex
    var channelCount: Int32
    var sampleFormat: PaSampleFormat
    var suggestedLatency: PaTime
    var hostApiSpecificStreamInfo: UnsafePointer[NoneType]


alias paFormatIsSupported: Int32 = 0


fn Pa_IsFormatSupported(
    inputParameters: UnsafePointer[PaStreamParameters],
    outputParameters: UnsafePointer[PaStreamParameters],
    sampleRate: Float64,
) -> PaError:
    """Determine whether it would be possible to open a stream with the specified parameters.
    """
    return external_call[
        "Pa_IsFormatSupported",
        PaError,
        UnsafePointer[PaStreamParameters],
        UnsafePointer[PaStreamParameters],
        Float64,
    ](inputParameters, outputParameters, sampleRate)


# ===========================
# Stream Types and Functions
# ===========================


@fieldwise_init
struct PaStream:
    pass


alias paFramesPerBufferUnspecified: UInt = 0

# Stream Flags
alias PaStreamFlags = UInt

alias paNoFlag: PaStreamFlags = 0
alias paClipOff: PaStreamFlags = 0x00000001
alias paDitherOff: PaStreamFlags = 0x00000002
alias paNeverDropInput: PaStreamFlags = 0x00000004
alias paPrimeOutputBuffersUsingStreamCallback: PaStreamFlags = 0x00000008
alias paPlatformSpecificFlags: PaStreamFlags = 0xFFFF0000


@fieldwise_init
struct PaStreamCallbackTimeInfo:
    var inputBufferAdcTime: PaTime
    var currentTime: PaTime
    var outputBufferDacTime: PaTime


# Stream Callback Flags
alias PaStreamCallbackFlags = UInt

alias paInputUnderflow: PaStreamCallbackFlags = 0x00000001
alias paInputOverflow: PaStreamCallbackFlags = 0x00000002
alias paOutputUnderflow: PaStreamCallbackFlags = 0x00000004
alias paOutputOverflow: PaStreamCallbackFlags = 0x00000008
alias paPrimingOutput: PaStreamCallbackFlags = 0x00000010

# Stream Callback Result
alias paContinue: Int32 = 0
alias paComplete: Int32 = 1
alias paAbort: Int32 = 2


fn Pa_OpenStream(
    stream: UnsafePointer[UnsafePointer[PaStream]],
    inputParameters: UnsafePointer[PaStreamParameters],
    outputParameters: UnsafePointer[PaStreamParameters],
    sampleRate: Float64,
    framesPerBuffer: UInt,
    streamFlags: PaStreamFlags,
    streamCallback: UnsafePointer[NoneType],
    userData: UnsafePointer[NoneType],
) -> PaError:
    """Opens a stream for either input, output or both."""
    return external_call[
        "Pa_OpenStream",
        PaError,
        UnsafePointer[UnsafePointer[PaStream]],
        UnsafePointer[PaStreamParameters],
        UnsafePointer[PaStreamParameters],
        Float64,
        UInt,
        PaStreamFlags,
        UnsafePointer[NoneType],
        UnsafePointer[NoneType],
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
    stream: UnsafePointer[UnsafePointer[PaStream]],
    numInputChannels: Int32,
    numOutputChannels: Int32,
    sampleFormat: PaSampleFormat,
    sampleRate: Float64,
    framesPerBuffer: UInt,
    streamCallback: UnsafePointer[NoneType],
    userData: UnsafePointer[NoneType],
) -> PaError:
    """A simplified version of Pa_OpenStream() that opens the default input and/or output devices.
    """
    return external_call[
        "Pa_OpenDefaultStream",
        PaError,
        UnsafePointer[UnsafePointer[PaStream]],
        Int32,
        Int32,
        PaSampleFormat,
        Float64,
        UInt,
        UnsafePointer[NoneType],
        UnsafePointer[NoneType],
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


fn Pa_CloseStream(stream: UnsafePointer[PaStream]) -> PaError:
    """Closes an audio stream."""
    return external_call["Pa_CloseStream", PaError, UnsafePointer[PaStream]](
        stream
    )


fn Pa_SetStreamFinishedCallback(
    stream: UnsafePointer[PaStream],
    streamFinishedCallback: UnsafePointer[NoneType],
) -> PaError:
    """Register a stream finished callback function."""
    return external_call[
        "Pa_SetStreamFinishedCallback",
        PaError,
        UnsafePointer[PaStream],
        UnsafePointer[NoneType],
    ](stream, streamFinishedCallback)


fn Pa_StartStream(stream: UnsafePointer[PaStream]) -> PaError:
    """Commences audio processing."""
    return external_call["Pa_StartStream", PaError, UnsafePointer[PaStream]](
        stream
    )


fn Pa_StopStream(stream: UnsafePointer[PaStream]) -> PaError:
    """Terminates audio processing."""
    return external_call["Pa_StopStream", PaError, UnsafePointer[PaStream]](
        stream
    )


fn Pa_AbortStream(stream: UnsafePointer[PaStream]) -> PaError:
    """Terminates audio processing promptly."""
    return external_call["Pa_AbortStream", PaError, UnsafePointer[PaStream]](
        stream
    )


fn Pa_IsStreamStopped(stream: UnsafePointer[PaStream]) -> PaError:
    """Determine whether the stream is stopped."""
    return external_call[
        "Pa_IsStreamStopped", PaError, UnsafePointer[PaStream]
    ](stream)


fn Pa_IsStreamActive(stream: UnsafePointer[PaStream]) -> PaError:
    """Determine whether the stream is active."""
    return external_call["Pa_IsStreamActive", PaError, UnsafePointer[PaStream]](
        stream
    )


@fieldwise_init
struct PaStreamInfo:
    var structVersion: Int32
    var inputLatency: PaTime
    var outputLatency: PaTime
    var sampleRate: Float64


fn Pa_GetStreamInfo(
    stream: UnsafePointer[PaStream],
) -> UnsafePointer[PaStreamInfo]:
    """Retrieve a pointer to a PaStreamInfo structure containing information about the specified stream.
    """
    return external_call[
        "Pa_GetStreamInfo", UnsafePointer[PaStreamInfo], UnsafePointer[PaStream]
    ](stream)


fn Pa_GetStreamTime(stream: UnsafePointer[PaStream]) -> PaTime:
    """Returns the current time in seconds for a stream."""
    return external_call["Pa_GetStreamTime", PaTime, UnsafePointer[PaStream]](
        stream
    )


fn Pa_GetStreamCpuLoad(stream: UnsafePointer[PaStream]) -> Float64:
    """Retrieve CPU usage information for the specified stream."""
    return external_call[
        "Pa_GetStreamCpuLoad", Float64, UnsafePointer[PaStream]
    ](stream)


fn Pa_ReadStream(
    stream: UnsafePointer[PaStream],
    buffer: UnsafePointer[NoneType],
    frames: UInt,
) -> PaError:
    """Read samples from an input stream."""
    return external_call[
        "Pa_ReadStream",
        PaError,
        UnsafePointer[PaStream],
        UnsafePointer[NoneType],
        UInt,
    ](stream, buffer, frames)


fn Pa_WriteStream(
    stream: UnsafePointer[PaStream],
    buffer: UnsafePointer[NoneType],
    frames: UInt,
) -> PaError:
    """Write samples to an output stream."""
    return external_call[
        "Pa_WriteStream",
        PaError,
        UnsafePointer[PaStream],
        UnsafePointer[NoneType],
        UInt,
    ](stream, buffer, frames)


fn Pa_GetStreamReadAvailable(stream: UnsafePointer[PaStream]) -> Int:
    """Retrieve the number of frames that can be read from the stream without waiting.
    """
    return external_call[
        "Pa_GetStreamReadAvailable", Int, UnsafePointer[PaStream]
    ](stream)


fn Pa_GetStreamWriteAvailable(stream: UnsafePointer[PaStream]) -> Int:
    """Retrieve the number of frames that can be written to the stream without waiting.
    """
    return external_call[
        "Pa_GetStreamWriteAvailable", Int, UnsafePointer[PaStream]
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
