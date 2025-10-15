from sys.ffi import external_call

alias GLFW_CONTEXT_VERSION_MAJOR = 0x00022002
alias GLFW_CONTEXT_VERSION_MINOR = 0x00022003
alias GLFW_OPENGL_FORWARD_COMPAT = 0x00022006
alias GLFW_OPENGL_PROFILE = 0x00022008
alias GLFW_OPENGL_CORE_PROFILE = 0x00032001
alias GLFW_COLOR_BUFFER_BIT = 0x00004000
alias GLFW_ESCAPE = 256
alias GLFW_KEY_ESCAPE = GLFW_ESCAPE
alias GLFW_KEY_R = 82
alias GLFW_PRESS = 1
alias GLFW_RELEASE = 0
alias GLFW_TRUE = 1


struct GLFWwindow:
    pass


fn glfw_get_framebuffer_size(
    window: UnsafePointer[GLFWwindow],
    width: UnsafePointer[Int32],
    height: UnsafePointer[Int32],
):
    _ = external_call[
        "glfwGetFramebufferSize",
        NoneType,
        UnsafePointer[GLFWwindow],
        UnsafePointer[Int32],
        UnsafePointer[Int32],
    ](window, width, height)


fn glfw_init() raises:
    var res = external_call["glfwInit", Int32]()
    if not res:
        raise Error("Failed to initialize GLFW")


fn glfw_terminate():
    external_call["glfwTerminate", NoneType]()


fn glfw_create_window(
    width: Int32, height: Int32, mut title: String
) raises -> UnsafePointer[GLFWwindow]:
    var res = external_call[
        "glfwCreateWindow",
        UnsafePointer[GLFWwindow],
        Int32,
        Int32,
        UnsafePointer[Int8],
        OpaquePointer,
        OpaquePointer,
    ](width, height, title.unsafe_cstr_ptr(), {}, {})
    if not res:
        glfw_terminate()
        raise Error("Failed to create GLFW window")
    return res


fn glfw_make_context_current(window: UnsafePointer[GLFWwindow]):
    _ = external_call[
        "glfwMakeContextCurrent", NoneType, UnsafePointer[GLFWwindow]
    ](window)


fn glfw_window_should_close(window: UnsafePointer[GLFWwindow]) -> Bool:
    return (
        external_call[
            "glfwWindowShouldClose", Int32, UnsafePointer[GLFWwindow]
        ](window)
        != 0
    )


fn glfw_swap_buffers(window: UnsafePointer[GLFWwindow]):
    _ = external_call["glfwSwapBuffers", NoneType, UnsafePointer[GLFWwindow]](
        window
    )


fn glfw_window_hint(hint: Int32, value: Int32):
    _ = external_call["glfwWindowHint", NoneType, Int32, Int32](hint, value)


fn glfw_set_error_callback(callback: fn (Int32, UnsafePointer[Int8]) -> None):
    _ = external_call[
        "glfwSetErrorCallback",
        NoneType,
        fn (Int32, UnsafePointer[Int8]) -> None,
    ](callback)


fn glfw_poll_events():
    _ = external_call["glfwPollEvents", NoneType]()


fn glfw_destroy_window(window: UnsafePointer[GLFWwindow]):
    _ = external_call["glfwDestroyWindow", NoneType, UnsafePointer[GLFWwindow]](
        window
    )


fn glfw_get_ns_gl_context(window: UnsafePointer[GLFWwindow]) -> OpaquePointer:
    return external_call[
        "glfwGetNSGLContext", OpaquePointer, UnsafePointer[GLFWwindow]
    ](window)


fn glfw_get_proc_address(procname: UnsafePointer[Int8]) -> OpaquePointer:
    return external_call[
        "glfwGetProcAddress", OpaquePointer, UnsafePointer[Int8]
    ](procname)


fn glfw_get_current_context() -> UnsafePointer[GLFWwindow]:
    return external_call["glfwGetCurrentContext", UnsafePointer[GLFWwindow]]()


fn glfw_get_error() -> (Int32, StaticString):
    var description = UnsafePointer[Int8]()
    var error_code = external_call[
        "glfwGetError", Int32, UnsafePointer[UnsafePointer[Int8]]
    ](UnsafePointer(to=description))
    if not description:
        return (error_code, "Unknown error")
    return (error_code, StaticString(unsafe_from_utf8_ptr=description))


fn glfw_get_key(window: UnsafePointer[GLFWwindow], key: Int32) -> Int32:
    return external_call["glfwGetKey", Int32, UnsafePointer[GLFWwindow], Int32](
        window, key
    )


fn glfw_set_window_should_close(
    window: UnsafePointer[GLFWwindow], value: Int32
):
    _ = external_call[
        "glfwSetWindowShouldClose", NoneType, UnsafePointer[GLFWwindow], Int32
    ](window, value)
