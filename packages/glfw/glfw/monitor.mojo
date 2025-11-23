import ._cffi


fn get_monitors() -> Span[Monitor, MutOrigin.external]:
    var count = Int32(0)
    var ptr = _cffi.glfwGetMonitors(UnsafePointer(to=count))
    return Span[Monitor, MutOrigin.external](
        ptr=ptr.unsafe_ptr().bitcast[Monitor](), length=Int(count)
    )


fn get_primary_monitor() -> Monitor:
    return Monitor(unsafe_raw_handle=_cffi.glfwGetPrimaryMonitor().unsafe_ptr())


fn set_monitor_callback[callback: MonitorFun]():
    fn _callback(
        monitor: _cffi.FFIPointer[_cffi.GLFWmonitor, mut=True],
        event: Int32,
    ):
        callback(
            Monitor(unsafe_raw_handle=monitor.unsafe_ptr()), MonitorEvent(event)
        )

    _ = _cffi.glfwSetMonitorCallback(_callback)


struct Monitor(Copyable, Movable):
    var _ptr: UnsafePointer[_cffi.GLFWmonitor, MutOrigin.external]

    fn __init__(
        out self,
        *,
        unsafe_raw_handle: UnsafePointer[_cffi.GLFWmonitor, MutOrigin.external],
    ):
        self._ptr = unsafe_raw_handle

    fn get_pos(self) -> Tuple[Int32, Int32]:
        var xpos: Int32 = 0
        var ypos: Int32 = 0
        _cffi.glfwGetMonitorPos(
            self._ptr, UnsafePointer(to=xpos), UnsafePointer(to=ypos)
        )
        return xpos, ypos

    fn get_workarea(self) -> Tuple[Int32, Int32, Int32, Int32]:
        """
        Get the monitor work area.

        Returns:
            The work area in order: x, y, width, height.
        """
        var xpos = Int32()
        var ypos = Int32()
        var width = Int32()
        var height = Int32()
        _cffi.glfwGetMonitorWorkarea(
            self._ptr,
            UnsafePointer(to=xpos),
            UnsafePointer(to=ypos),
            UnsafePointer(to=width),
            UnsafePointer(to=height),
        )
        return xpos, ypos, width, height

    fn get_physical_size(self) -> Tuple[Int32, Int32]:
        """
        Get the physical size of the monitor in millimeters.

        Returns:
            The physical size in order: widthMM, heightMM.
        """
        var width_mm: Int32 = 0
        var height_mm: Int32 = 0
        _cffi.glfwGetMonitorPhysicalSize(
            self._ptr, UnsafePointer(to=width_mm), UnsafePointer(to=height_mm)
        )
        return width_mm, height_mm

    fn get_content_scale(self) -> Tuple[Float32, Float32]:
        var x_scale: Float32 = 0
        var y_scale: Float32 = 0
        _cffi.glfwGetMonitorContentScale(
            self._ptr, UnsafePointer(to=x_scale), UnsafePointer(to=y_scale)
        )
        return x_scale, y_scale

    # fn get_name(self) -> StaticString:
    #     return StaticString(
    #         unsafe_from_utf8_ptr=_cffi.glfwGetMonitorName(self._ptr)
    #     )

    fn set_user_pointer[T: AnyType](mut self, ptr: UnsafePointer[mut=True, T]):
        _cffi.glfwSetMonitorUserPointer(self._ptr, ptr.bitcast[NoneType]())

    fn get_user_pointer[
        T: AnyType
    ](self) -> UnsafePointer[T, MutOrigin.external]:
        return (
            _cffi.glfwGetMonitorUserPointer(self._ptr).unsafe_ptr().bitcast[T]()
        )

    fn get_video_mode(self) -> VidMode:
        """Get the current video mode of the monitor."""
        var mode_ptr = _cffi.glfwGetVideoMode(self._ptr)
        return mode_ptr.unsafe_ptr()[]

    fn set_gamma(mut self, gamma: Float32):
        _cffi.glfwSetGamma(self._ptr, gamma)

    fn get_gamma_ramp(self) -> GammaRamp:
        """Get the gamma ramp for the monitor."""
        var ramp_ptr = _cffi.glfwGetGammaRamp(self._ptr).unsafe_ptr()
        return ramp_ptr[]

    fn set_gamma_ramp(mut self, ramp: UnsafePointer[mut=True, GammaRamp]):
        _cffi.glfwSetGammaRamp(self._ptr, ramp)

    fn get_video_modes(self) -> Span[VidMode, ImmutOrigin.external]:
        """Get all available video modes for the monitor."""
        var count = Int32(0)
        var ptr = _cffi.glfwGetVideoModes(
            self._ptr, _cffi.FFIPointer[mut=True](UnsafePointer(to=count))
        )
        return Span[VidMode, ImmutOrigin.external](
            ptr=ptr.unsafe_ptr(), length=Int(count)
        )
