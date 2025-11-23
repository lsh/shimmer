import ._cffi
from .enums import Attribute
from .functions import *
from .monitor import Monitor


struct Window(Movable):
    var _ptr: UnsafePointer[_cffi.GLFWwindow, MutOrigin.external]
    var _owning: Bool

    fn __init__(
        out self,
        *,
        unsafe_raw_handle: UnsafePointer[_cffi.GLFWwindow, MutOrigin.external],
        owning: Bool,
    ):
        self._ptr = unsafe_raw_handle
        self._owning = owning

    fn __init__(
        out self,
        width: Int32,
        height: Int32,
        mut title: String,
    ):
        self._ptr = _cffi.glfwCreateWindow(
            width, height, title.unsafe_cstr_ptr(), {}, {}
        ).unsafe_ptr()
        self._owning = True

    fn __init__(
        out self,
        width: Int32,
        height: Int32,
        mut title: String,
        mut monitor: Monitor,
    ):
        self._ptr = _cffi.glfwCreateWindow(
            width, height, title.unsafe_cstr_ptr(), monitor._ptr, {}
        ).unsafe_ptr()
        self._owning = True

    fn __del__(deinit self):
        if self._owning:
            _cffi.glfwDestroyWindow(self._ptr)

    fn should_close(self) -> Bool:
        return Bool(_cffi.glfwWindowShouldClose(self._ptr))

    fn set_should_close(mut self, value: Bool) -> Bool:
        return Bool(
            _cffi.glfwSetWindowShouldClose(
                self._ptr, _cffi.GLFW_TRUE if value else _cffi.GLFW_FALSE
            )
        )

    fn set_title(mut self, mut title: String):
        _cffi.glfwSetWindowTitle(self._ptr, title.unsafe_cstr_ptr())

    fn set_icon(mut self, images: Span[mut=False, Image]):
        _cffi.glfwSetWindowIcon(self._ptr, len(images), images.unsafe_ptr())

    fn get_pos(self) -> Tuple[Int32, Int32]:
        var xpos: Int32 = 0
        var ypos: Int32 = 0
        _cffi.glfwGetWindowPos(
            self._ptr, UnsafePointer(to=xpos), UnsafePointer(to=ypos)
        )
        return xpos, ypos

    fn set_pos(mut self, x: Int32, y: Int32):
        _cffi.glfwSetWindowPos(self._ptr, x, y)

    fn get_size(self) -> Tuple[Int32, Int32]:
        var width: Int32 = 0
        var height: Int32 = 0
        _cffi.glfwGetWindowSize(
            self._ptr, UnsafePointer(to=width), UnsafePointer(to=height)
        )
        return width, height

    fn set_size_limits(
        mut self,
        min_width: Int32,
        min_height: Int32,
        max_width: Int32,
        max_height: Int32,
    ):
        _cffi.glfwSetWindowSizeLimits(
            self._ptr, min_width, min_height, max_width, max_height
        )

    fn set_aspect_ratio(mut self, numer: Int32, denom: Int32):
        _cffi.glfwSetWindowAspectRatio(self._ptr, numer, denom)

    fn set_size(mut self, width: Int32, height: Int32):
        _cffi.glfwSetWindowSize(self._ptr, width, height)

    fn get_framebuffer_size(self) -> Tuple[Int32, Int32]:
        var width: Int32 = 0
        var height: Int32 = 0
        _cffi.glfwGetFramebufferSize(
            self._ptr, UnsafePointer(to=width), UnsafePointer(to=height)
        )
        return width, height

    fn get_frame_size(
        self,
    ) -> Tuple[Int32, Int32, Int32, Int32]:
        """
        Get the window frame size.

        Returns:
            The frame size in order: left, top, right, bottom.
        """
        var left = Int32()
        var top = Int32()
        var right = Int32()
        var bottom = Int32()
        _cffi.glfwGetWindowFrameSize(
            self._ptr,
            UnsafePointer(to=left),
            UnsafePointer(to=top),
            UnsafePointer(to=right),
            UnsafePointer(to=bottom),
        )
        return left, top, right, bottom

    fn get_content_scale(self) -> Tuple[Float32, Float32]:
        var x_scale: Float32 = 0
        var y_scale: Float32 = 0
        _cffi.glfwGetWindowContentScale(
            self._ptr, UnsafePointer(to=x_scale), UnsafePointer(to=y_scale)
        )
        return x_scale, y_scale

    fn get_opacity(self) -> Float32:
        return _cffi.glfwGetWindowOpacity(self._ptr)

    fn set_opacity(mut self, opacity: Float32):
        return _cffi.glfwSetWindowOpacity(self._ptr, opacity)

    fn iconify(mut self):
        _cffi.glfwIconifyWindow(self._ptr)

    fn restore(mut self):
        _cffi.glfwRestoreWindow(self._ptr)

    fn maximize(mut self):
        _cffi.glfwMaximizeWindow(self._ptr)

    fn show(mut self):
        _cffi.glfwShowWindow(self._ptr)

    fn hide(mut self):
        _cffi.glfwHideWindow(self._ptr)

    fn focus(mut self):
        _cffi.glfwFocusWindow(self._ptr)

    fn request_attention(mut self):
        _cffi.glfwRequestWindowAttention(self._ptr)

    fn get_monitor(self) -> Monitor:
        return Monitor(
            unsafe_raw_handle=_cffi.glfwGetWindowMonitor(self._ptr).unsafe_ptr()
        )

    fn set_monitor(
        self,
        mut monitor: Monitor,
        xpos: Int32,
        ypos: Int32,
        width: Int32,
        height: Int32,
        refresh_rate: Int32,
    ):
        _cffi.glfwSetWindowMonitor(
            self._ptr, monitor._ptr, xpos, ypos, width, height, refresh_rate
        )

    fn get_attrib(self, attribute: Attribute) -> Bool:
        return Bool(_cffi.glfwGetWindowAttrib(self._ptr, attribute._value))

    fn set_attrib(self, attribute: Attribute, value: Bool):
        _cffi.glfwSetWindowAttrib(
            self._ptr,
            attribute._value,
            _cffi.GLFW_TRUE if value else _cffi.GLFW_FALSE,
        )

    fn set_user_pointer[T: AnyType](mut self, ptr: UnsafePointer[mut=True, T]):
        _cffi.glfwSetWindowUserPointer(self._ptr, ptr.bitcast[NoneType]())

    fn get_user_pointer[
        T: AnyType
    ](self) -> UnsafePointer[T, MutOrigin.external]:
        return (
            _cffi.glfwGetWindowUserPointer(self._ptr).unsafe_ptr().bitcast[T]()
        )

    fn set_pos_callback[callback: WindowPosFun](mut self):
        fn _callback(
            ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True],
            x: Int32,
            y: Int32,
        ):
            callback(
                Window(unsafe_raw_handle=ptr.unsafe_ptr(), owning=False), x, y
            )

        _ = _cffi.glfwSetWindowPosCallback(self._ptr, _callback)

    fn set_size_callback[callback: WindowSizeFun](mut self):
        fn _callback(
            ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True],
            width: Int32,
            height: Int32,
        ):
            callback(
                Window(unsafe_raw_handle=ptr.unsafe_ptr(), owning=False),
                width,
                height,
            )

        _ = _cffi.glfwSetWindowSizeCallback(self._ptr, _callback)

    fn set_close_callback[callback: WindowCloseFun](mut self):
        fn _callback(ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True]):
            callback(Window(unsafe_raw_handle=ptr.unsafe_ptr(), owning=False))

        _ = _cffi.glfwSetWindowCloseCallback(self._ptr, _callback)

    fn set_refresh_callback[callback: WindowRefreshFun](mut self):
        fn _callback(ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True]):
            callback(Window(unsafe_raw_handle=ptr.unsafe_ptr(), owning=False))

        _ = _cffi.glfwSetWindowRefreshCallback(self._ptr, _callback)

    fn set_focus_callback[callback: WindowFocusFun](mut self):
        fn _callback(
            ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True],
            focused: Int32,
        ):
            callback(
                Window(unsafe_raw_handle=ptr.unsafe_ptr(), owning=False),
                Bool(focused),
            )

        _ = _cffi.glfwSetWindowFocusCallback(self._ptr, _callback)

    fn set_iconify_callback[callback: WindowIconifyFun](mut self):
        fn _callback(
            ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True],
            iconified: Int32,
        ):
            callback(
                Window(unsafe_raw_handle=ptr.unsafe_ptr(), owning=False),
                Bool(iconified),
            )

        _ = _cffi.glfwSetWindowIconifyCallback(self._ptr, _callback)

    fn set_maximize_callback[callback: WindowMaximizeFun](mut self):
        fn _callback(
            ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True],
            maximized: Int32,
        ):
            callback(
                Window(unsafe_raw_handle=ptr.unsafe_ptr(), owning=False),
                Bool(maximized),
            )

        _ = _cffi.glfwSetWindowMaximizeCallback(self._ptr, _callback)

    fn set_framebuffer_size_callback[callback: FramebufferSizeFun](mut self):
        fn _callback(
            ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True],
            width: Int32,
            height: Int32,
        ):
            callback(
                Window(unsafe_raw_handle=ptr.unsafe_ptr(), owning=False),
                width,
                height,
            )

        _ = _cffi.glfwSetFramebufferSizeCallback(self._ptr, _callback)

    fn set_content_scale_callback[callback: WindowContentScaleFun](mut self):
        fn _callback(
            ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True],
            xscale: Float32,
            yscale: Float32,
        ):
            callback(
                Window(unsafe_raw_handle=ptr.unsafe_ptr(), owning=False),
                xscale,
                yscale,
            )

        _ = _cffi.glfwSetWindowContentScaleCallback(self._ptr, _callback)

    fn get_input_mode(self, mode: InputMode) -> Int32:
        return _cffi.glfwGetInputMode(self._ptr, mode._value)

    fn set_input_mode(self, mode: InputMode, value: Bool):
        _cffi.glfwSetInputMode(
            self._ptr,
            mode._value,
            _cffi.GLFW_TRUE if value else _cffi.GLFW_FALSE,
        )

    fn get_key(self, key: Key) -> Int32:
        return _cffi.glfwGetKey(self._ptr, key._value)

    fn get_mouse_button(self, button: MouseButton) -> Int32:
        return _cffi.glfwGetMouseButton(self._ptr, button._value)

    fn get_cursor_pos(self) -> Tuple[Float64, Float64]:
        var x_pos: Float64 = 0
        var y_pos: Float64 = 0
        _cffi.glfwGetCursorPos(
            self._ptr, UnsafePointer(to=x_pos), UnsafePointer(to=y_pos)
        )
        return x_pos, y_pos

    fn set_cursor_pos(mut self, xpos: Float64, ypos: Float64):
        _cffi.glfwSetCursorPos(self._ptr, xpos, ypos)

    fn set_cursor(self, cursor: UnsafePointer[mut=True, _cffi.GLFWcursor]):
        _cffi.glfwSetCursor(self._ptr, cursor)

    fn set_key_callback[callback: KeyFun](mut self):
        fn _callback(
            ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True],
            key: Int32,
            scancode: Int32,
            action: Int32,
            mods: Int32,
        ):
            callback(
                Window(unsafe_raw_handle=ptr.unsafe_ptr(), owning=False),
                enums.Key(key),
                scancode,
                enums.Action(action),
                enums.Mod(mods),
            )

        _ = _cffi.glfwSetKeyCallback(self._ptr, _callback)

    fn set_char_callback[callback: CharFun](mut self):
        fn _callback(
            ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True],
            codepoint: UInt32,
        ):
            callback(
                Window(unsafe_raw_handle=ptr.unsafe_ptr(), owning=False),
                Codepoint(unsafe_unchecked_codepoint=codepoint),
            )

        _ = _cffi.glfwSetCharCallback(self._ptr, _callback)

    fn set_char_mods_callback[callback: CharModsFun](mut self):
        fn _callback(
            ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True],
            codepoint: UInt32,
            mods: Int32,
        ):
            callback(
                Window(unsafe_raw_handle=ptr.unsafe_ptr(), owning=False),
                Codepoint(unsafe_unchecked_codepoint=codepoint),
                enums.Mod(mods),
            )

        _ = _cffi.glfwSetCharModsCallback(self._ptr, _callback)

    fn set_mouse_button_callback[callback: MouseButtonFun](mut self):
        fn _callback(
            ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True],
            button: Int32,
            action: Int32,
            mods: Int32,
        ):
            callback(
                Window(unsafe_raw_handle=ptr.unsafe_ptr(), owning=False),
                button,
                action,
                mods,
            )

        _ = _cffi.glfwSetMouseButtonCallback(self._ptr, _callback)

    fn set_cursor_pos_callback[callback: CursorPosFun](mut self):
        fn _callback(
            ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True],
            xpos: Float64,
            ypos: Float64,
        ):
            callback(
                Window(unsafe_raw_handle=ptr.unsafe_ptr(), owning=False),
                xpos,
                ypos,
            )

        _ = _cffi.glfwSetCursorPosCallback(self._ptr, _callback)

    fn set_cursor_enter_callback[callback: CursorEnterFun](mut self):
        fn _callback(
            ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True],
            entered: Int32,
        ):
            callback(
                Window(unsafe_raw_handle=ptr.unsafe_ptr(), owning=False),
                Bool(entered),
            )

        _ = _cffi.glfwSetCursorEnterCallback(self._ptr, _callback)

    fn set_scroll_callback[callback: ScrollFun](mut self):
        fn _callback(
            ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True],
            xoffset: Float64,
            yoffset: Float64,
        ):
            callback(
                Window(unsafe_raw_handle=ptr.unsafe_ptr(), owning=False),
                xoffset,
                yoffset,
            )

        _ = _cffi.glfwSetScrollCallback(self._ptr, _callback)

    # fn set_drop_callback[callback: DropFun](mut self):
    #     fn _callback(
    #         ptr: _cffi.FFIPointer[_cffi.GLFWwindow, mut=True],
    #         count: Int32,
    #         paths: _cffi.FFIPointer[
    #             _cffi.FFIPointer[Int8, mut=False], mut=False
    #         ],
    #     ):
    #         var path_list = List[StaticString]()
    #         for i in range(count):
    #             path_list.append(StaticString(unsafe_from_utf8_ptr=paths[i]))
    #         callback(Window(unsafe_raw_handle=ptr, owning=False), path_list^)

    #     _ = _cffi.glfwSetDropCallback(self._ptr, _callback)

    fn set_clipboard_string(self, mut string: String):
        _cffi.glfwSetClipboardString(self._ptr, string.unsafe_cstr_ptr())

    # fn get_clipboard_string(
    #     self,
    # ) -> StaticString:
    #     return StaticString(
    #         unsafe_from_utf8_ptr=_cffi.glfwGetClipboardString(self._ptr)
    #     )

    fn make_context_current(self):
        _cffi.glfwMakeContextCurrent(self._ptr)

    fn swap_buffers(mut self):
        _cffi.glfwSwapBuffers(self._ptr)

    @staticmethod
    fn default_hints():
        _ = _cffi.glfwDefaultWindowHints()

    @staticmethod
    fn hint(hint: ContextHint, value: ContextHint):
        _ = _cffi.glfwWindowHint(hint._value, value._value)

    @staticmethod
    fn hint_string(hint: ContextHint, mut value: String):
        _ = _cffi.glfwWindowHintString(hint._value, value.unsafe_cstr_ptr())

    fn get_cocoa_window(self) -> _cffi.FFIPointer[NoneType, mut=True]:
        return _cffi.glfwGetCocoaWindow(self._ptr)
