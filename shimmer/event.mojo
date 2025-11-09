from shimmer._time import Duration
from shimmer.geom import Vec2

from utils import Variant


trait LoopEvent(Movable):
    """
    Event types that are compatible with the shimmer loop.
    """

    fn __init__(out self, var update: Update):
        ...

    fn __init__(out self, var window_event: WindowEvent):
        ...


struct Event(Copyable, LoopEvent, Movable, Writable):
    var _value: Variant[Update, WindowEvent]

    @implicit
    fn __init__(out self, var update: Update):
        self._value = update^

    @implicit
    fn __init__(out self, var window_event: WindowEvent):
        self._value = window_event^

    fn is_update(self) -> Bool:
        return self._value.isa[Update]()

    fn get_update(ref self) -> ref [self._value] Update:
        return self._value[Update]

    fn is_window_event(self) -> Bool:
        return self._value.isa[WindowEvent]()

    fn get_window_event(ref self) -> ref [self._value] WindowEvent:
        return self._value[WindowEvent]

    fn write_to(self, mut w: Some[Writer]):
        w.write("Event(")
        if self.is_update():
            w.write(self.get_update())
        elif self.is_window_event():
            w.write(self.get_window_event())
        w.write(")")


@fieldwise_init
struct Update(Copyable, Movable, Writable):
    var since_last: Duration
    var since_start: Duration

    fn write_to(self, mut w: Some[Writer]):
        w.write("Update()")


@fieldwise_init
struct Resized(Copyable, ImplicitlyCopyable, Movable, Writable):
    var value: Vec2

    fn write_to(self, mut w: Some[Writer]):
        w.write("Resized(", self.value.x, ", ", self.value.y, ")")


struct WindowEvent(Copyable, Movable, Writable):
    var _value: Variant[Resized]

    fn __init__(out self, value: Resized):
        self._value = value

    fn is_resized(self) -> Bool:
        return self._value.isa[Resized]()

    fn get_resized(ref self) -> ref [self._value] Resized:
        return self._value[Resized]

    @staticmethod
    fn resized(size: Vec2) -> Self:
        return Self(Resized(size))

    fn write_to(self, mut w: Some[Writer]):
        w.write("WindowEvent(")
        if self.is_resized():
            w.write(self.get_resized())
        w.write(")")
