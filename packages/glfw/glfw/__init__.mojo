from .enums import *
from .monitor import *
from .window import *
import ._cffi

comptime Image = _cffi.GLFWimage
comptime VidMode = _cffi.GLFWvidmode
comptime GammaRamp = _cffi.GLFWgammaramp


fn init() raises:
    if not _cffi.glfwInit():
        raise Error("Failed to initialize GLFW")


fn terminate():
    _cffi.glfwTerminate()


fn poll_events():
    _cffi.glfwPollEvents()
