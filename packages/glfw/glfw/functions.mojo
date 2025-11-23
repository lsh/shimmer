import .enums
from .monitor import Monitor
from .window import Window

comptime GLFWglproc = fn () -> None
comptime GLFWvkproc = fn () -> None

# Callback function types
comptime ErrorFun = fn (enums.Error, StaticString) -> None
comptime WindowPosFun = fn (var Window, Int32, Int32) -> None
comptime WindowSizeFun = fn (var Window, Int32, Int32) -> None
comptime WindowCloseFun = fn (var Window) -> None
comptime WindowRefreshFun = fn (var Window) -> None
comptime WindowFocusFun = fn (var Window, Bool) -> None
comptime WindowIconifyFun = fn (var Window, Bool) -> None
comptime WindowMaximizeFun = fn (var Window, Bool) -> None
comptime FramebufferSizeFun = fn (var Window, Int32, Int32) -> None
comptime WindowContentScaleFun = fn (var Window, Float32, Float32) -> None
comptime MouseButtonFun = fn (var Window, Int32, Int32, Int32) -> None
comptime CursorPosFun = fn (var Window, Float64, Float64) -> None
comptime CursorEnterFun = fn (var Window, Bool) -> None
comptime ScrollFun = fn (var Window, Float64, Float64) -> None
comptime KeyFun = fn (
    var Window, enums.Key, Int32, enums.Action, enums.Mod
) -> None
comptime CharFun = fn (var Window, Codepoint) -> None
comptime CharModsFun = fn (var Window, Codepoint, enums.Mod) -> None
comptime DropFun = fn (var Window, var List[StaticString]) -> None
comptime MonitorFun = fn (var Monitor, MonitorEvent) -> None
comptime JoystickFun = fn (Int32, Int32) -> None
