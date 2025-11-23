import ._cffi

comptime DONT_CARE = -1


@fieldwise_init
struct Version(Copyable, ImplicitlyCopyable, Movable, Writable):
    comptime major = _cffi.GLFW_VERSION_MAJOR
    comptime minor = _cffi.GLFW_VERSION_MINOR
    comptime revision = _cffi.GLFW_VERSION_REVISION

    fn write_to(self, mut w: Some[Writer]):
        w.write(
            "Version(",
            "major=",
            self.major,
            ", minor=",
            self.minor,
            ", revision=",
            self.revision,
            ")",
        )


@fieldwise_init
struct Action(
    Copyable, EqualityComparable, ImplicitlyCopyable, Movable, Writable
):
    var _value: Int32
    comptime release = Self(_cffi.GLFW_RELEASE)
    comptime press = Self(_cffi.GLFW_PRESS)
    comptime repeat = Self(_cffi.GLFW_REPEAT)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.release:
            w.write("Action.release")
        elif self == Self.press:
            w.write("Action.press")
        elif self == Self.repeat:
            w.write("Action.repeat")


@fieldwise_init
struct Hat(Copyable, EqualityComparable, ImplicitlyCopyable, Movable, Writable):
    var _value: Int32
    comptime centered = Self(_cffi.GLFW_HAT_CENTERED)
    comptime up = Self(_cffi.GLFW_HAT_UP)
    comptime right = Self(_cffi.GLFW_HAT_RIGHT)
    comptime down = Self(_cffi.GLFW_HAT_DOWN)
    comptime left = Self(_cffi.GLFW_HAT_LEFT)
    comptime right_up = Self(_cffi.GLFW_HAT_RIGHT_UP)
    comptime right_down = Self(_cffi.GLFW_HAT_RIGHT_DOWN)
    comptime left_up = Self(_cffi.GLFW_HAT_LEFT_UP)
    comptime left_down = Self(_cffi.GLFW_HAT_LEFT_DOWN)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.centered:
            w.write("Hat.centered")
        elif self == Self.up:
            w.write("Hat.up")
        elif self == Self.right:
            w.write("Hat.right")
        elif self == Self.down:
            w.write("Hat.down")
        elif self == Self.left:
            w.write("Hat.left")
        elif self == Self.right_up:
            w.write("Hat.right_up")
        elif self == Self.right_down:
            w.write("Hat.right_down")
        elif self == Self.left_up:
            w.write("Hat.left_up")
        elif self == Self.left_down:
            w.write("Hat.left_down")


@fieldwise_init
struct Key(Copyable, EqualityComparable, ImplicitlyCopyable, Movable, Writable):
    var _value: Int32

    comptime unknown = Self(-1)

    # Printable keys
    comptime space = Self(_cffi.GLFW_KEY_SPACE)
    comptime apostrophe = Self(_cffi.GLFW_KEY_APOSTROPHE)  # '
    comptime comma = Self(_cffi.GLFW_KEY_COMMA)  # ,
    comptime minus = Self(_cffi.GLFW_KEY_MINUS)  # -
    comptime period = Self(_cffi.GLFW_KEY_PERIOD)  # .
    comptime slash = Self(_cffi.GLFW_KEY_SLASH)  # /
    comptime zero = Self(_cffi.GLFW_KEY_0)
    comptime one = Self(_cffi.GLFW_KEY_1)
    comptime two = Self(_cffi.GLFW_KEY_2)
    comptime three = Self(_cffi.GLFW_KEY_3)
    comptime four = Self(_cffi.GLFW_KEY_4)
    comptime five = Self(_cffi.GLFW_KEY_5)
    comptime six = Self(_cffi.GLFW_KEY_6)
    comptime seven = Self(_cffi.GLFW_KEY_7)
    comptime eight = Self(_cffi.GLFW_KEY_8)
    comptime nine = Self(_cffi.GLFW_KEY_9)
    comptime semicolon = Self(_cffi.GLFW_KEY_SEMICOLON)  # ;
    comptime equal = Self(_cffi.GLFW_KEY_EQUAL)  # =
    comptime a = Self(_cffi.GLFW_KEY_A)
    comptime b = Self(_cffi.GLFW_KEY_B)
    comptime c = Self(_cffi.GLFW_KEY_C)
    comptime d = Self(_cffi.GLFW_KEY_D)
    comptime e = Self(_cffi.GLFW_KEY_E)
    comptime f = Self(_cffi.GLFW_KEY_F)
    comptime g = Self(_cffi.GLFW_KEY_G)
    comptime h = Self(_cffi.GLFW_KEY_H)
    comptime i = Self(_cffi.GLFW_KEY_I)
    comptime j = Self(_cffi.GLFW_KEY_J)
    comptime k = Self(_cffi.GLFW_KEY_K)
    comptime l = Self(_cffi.GLFW_KEY_L)
    comptime m = Self(_cffi.GLFW_KEY_M)
    comptime n = Self(_cffi.GLFW_KEY_N)
    comptime o = Self(_cffi.GLFW_KEY_O)
    comptime p = Self(_cffi.GLFW_KEY_P)
    comptime q = Self(_cffi.GLFW_KEY_Q)
    comptime r = Self(_cffi.GLFW_KEY_R)
    comptime s = Self(_cffi.GLFW_KEY_S)
    comptime t = Self(_cffi.GLFW_KEY_T)
    comptime u = Self(_cffi.GLFW_KEY_U)
    comptime v = Self(_cffi.GLFW_KEY_V)
    comptime w = Self(_cffi.GLFW_KEY_W)
    comptime x = Self(_cffi.GLFW_KEY_X)
    comptime y = Self(_cffi.GLFW_KEY_Y)
    comptime z = Self(_cffi.GLFW_KEY_Z)
    comptime left_bracket = Self(_cffi.GLFW_KEY_LEFT_BRACKET)  # [
    comptime backslash = Self(_cffi.GLFW_KEY_BACKSLASH)  # \
    comptime right_bracket = Self(_cffi.GLFW_KEY_RIGHT_BRACKET)  # ]
    comptime grave_accent = Self(_cffi.GLFW_KEY_GRAVE_ACCENT)  # `
    comptime world_1 = Self(_cffi.GLFW_KEY_WORLD_1)  # non-US #1
    comptime world_2 = Self(_cffi.GLFW_KEY_WORLD_2)  # non-US #2

    # Function keys
    comptime escape = Self(_cffi.GLFW_KEY_ESCAPE)
    comptime enter = Self(_cffi.GLFW_KEY_ENTER)
    comptime tab = Self(_cffi.GLFW_KEY_TAB)
    comptime backspace = Self(_cffi.GLFW_KEY_BACKSPACE)
    comptime insert = Self(_cffi.GLFW_KEY_INSERT)
    comptime delete = Self(_cffi.GLFW_KEY_DELETE)
    comptime right = Self(_cffi.GLFW_KEY_RIGHT)
    comptime left = Self(_cffi.GLFW_KEY_LEFT)
    comptime down = Self(_cffi.GLFW_KEY_DOWN)
    comptime up = Self(_cffi.GLFW_KEY_UP)
    comptime page_up = Self(_cffi.GLFW_KEY_PAGE_UP)
    comptime page_down = Self(_cffi.GLFW_KEY_PAGE_DOWN)
    comptime home = Self(_cffi.GLFW_KEY_HOME)
    comptime end = Self(_cffi.GLFW_KEY_END)
    comptime caps_lock = Self(_cffi.GLFW_KEY_CAPS_LOCK)
    comptime scroll_lock = Self(_cffi.GLFW_KEY_SCROLL_LOCK)
    comptime num_lock = Self(_cffi.GLFW_KEY_NUM_LOCK)
    comptime print_screen = Self(_cffi.GLFW_KEY_PRINT_SCREEN)
    comptime pause = Self(_cffi.GLFW_KEY_PAUSE)
    comptime f1 = Self(_cffi.GLFW_KEY_F1)
    comptime f2 = Self(_cffi.GLFW_KEY_F2)
    comptime f3 = Self(_cffi.GLFW_KEY_F3)
    comptime f4 = Self(_cffi.GLFW_KEY_F4)
    comptime f5 = Self(_cffi.GLFW_KEY_F5)
    comptime f6 = Self(_cffi.GLFW_KEY_F6)
    comptime f7 = Self(_cffi.GLFW_KEY_F7)
    comptime f8 = Self(_cffi.GLFW_KEY_F8)
    comptime f9 = Self(_cffi.GLFW_KEY_F9)
    comptime f10 = Self(_cffi.GLFW_KEY_F10)
    comptime f11 = Self(_cffi.GLFW_KEY_F11)
    comptime f12 = Self(_cffi.GLFW_KEY_F12)
    comptime f13 = Self(_cffi.GLFW_KEY_F13)
    comptime f14 = Self(_cffi.GLFW_KEY_F14)
    comptime f15 = Self(_cffi.GLFW_KEY_F15)
    comptime f16 = Self(_cffi.GLFW_KEY_F16)
    comptime f17 = Self(_cffi.GLFW_KEY_F17)
    comptime f18 = Self(_cffi.GLFW_KEY_F18)
    comptime f19 = Self(_cffi.GLFW_KEY_F19)
    comptime f20 = Self(_cffi.GLFW_KEY_F20)
    comptime f21 = Self(_cffi.GLFW_KEY_F21)
    comptime f22 = Self(_cffi.GLFW_KEY_F22)
    comptime f23 = Self(_cffi.GLFW_KEY_F23)
    comptime f24 = Self(_cffi.GLFW_KEY_F24)
    comptime f25 = Self(_cffi.GLFW_KEY_F25)
    comptime kp_0 = Self(_cffi.GLFW_KEY_KP_0)
    comptime kp_1 = Self(_cffi.GLFW_KEY_KP_1)
    comptime kp_2 = Self(_cffi.GLFW_KEY_KP_2)
    comptime kp_3 = Self(_cffi.GLFW_KEY_KP_3)
    comptime kp_4 = Self(_cffi.GLFW_KEY_KP_4)
    comptime kp_5 = Self(_cffi.GLFW_KEY_KP_5)
    comptime kp_6 = Self(_cffi.GLFW_KEY_KP_6)
    comptime kp_7 = Self(_cffi.GLFW_KEY_KP_7)
    comptime kp_8 = Self(_cffi.GLFW_KEY_KP_8)
    comptime kp_9 = Self(_cffi.GLFW_KEY_KP_9)
    comptime kp_decimal = Self(_cffi.GLFW_KEY_KP_DECIMAL)
    comptime kp_divide = Self(_cffi.GLFW_KEY_KP_DIVIDE)
    comptime kp_multiply = Self(_cffi.GLFW_KEY_KP_MULTIPLY)
    comptime kp_subtract = Self(_cffi.GLFW_KEY_KP_SUBTRACT)
    comptime kp_add = Self(_cffi.GLFW_KEY_KP_ADD)
    comptime kp_enter = Self(_cffi.GLFW_KEY_KP_ENTER)
    comptime kp_equal = Self(_cffi.GLFW_KEY_KP_EQUAL)
    comptime left_shift = Self(_cffi.GLFW_KEY_LEFT_SHIFT)
    comptime left_control = Self(_cffi.GLFW_KEY_LEFT_CONTROL)
    comptime left_alt = Self(_cffi.GLFW_KEY_LEFT_ALT)
    comptime left_super = Self(_cffi.GLFW_KEY_LEFT_SUPER)
    comptime right_shift = Self(_cffi.GLFW_KEY_RIGHT_SHIFT)
    comptime right_control = Self(_cffi.GLFW_KEY_RIGHT_CONTROL)
    comptime right_alt = Self(_cffi.GLFW_KEY_RIGHT_ALT)
    comptime right_super = Self(_cffi.GLFW_KEY_RIGHT_SUPER)
    comptime menu = Self(_cffi.GLFW_KEY_MENU)

    comptime last = Self.menu

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.space:
            w.write("Key.space")
        elif self == Self.apostrophe:
            w.write("Key.apostrophe")
        elif self == Self.comma:
            w.write("Key.comma")
        elif self == Self.minus:
            w.write("Key.minus")
        elif self == Self.period:
            w.write("Key.period")
        elif self == Self.slash:
            w.write("Key.slash")
        elif self == Self.zero:
            w.write("Key.zero")
        elif self == Self.one:
            w.write("Key.one")
        elif self == Self.two:
            w.write("Key.two")
        elif self == Self.three:
            w.write("Key.three")
        elif self == Self.four:
            w.write("Key.four")
        elif self == Self.five:
            w.write("Key.five")
        elif self == Self.six:
            w.write("Key.six")
        elif self == Self.seven:
            w.write("Key.seven")
        elif self == Self.eight:
            w.write("Key.eight")
        elif self == Self.nine:
            w.write("Key.nine")
        elif self == Self.semicolon:
            w.write("Key.semicolon")
        elif self == Self.equal:
            w.write("Key.equal")
        elif self == Self.a:
            w.write("Key.a")
        elif self == Self.b:
            w.write("Key.b")
        elif self == Self.c:
            w.write("Key.c")
        elif self == Self.d:
            w.write("Key.d")
        elif self == Self.e:
            w.write("Key.e")
        elif self == Self.f:
            w.write("Key.f")
        elif self == Self.g:
            w.write("Key.g")
        elif self == Self.h:
            w.write("Key.h")
        elif self == Self.i:
            w.write("Key.i")
        elif self == Self.j:
            w.write("Key.j")
        elif self == Self.k:
            w.write("Key.k")
        elif self == Self.l:
            w.write("Key.l")
        elif self == Self.m:
            w.write("Key.m")
        elif self == Self.n:
            w.write("Key.n")
        elif self == Self.o:
            w.write("Key.o")
        elif self == Self.p:
            w.write("Key.p")
        elif self == Self.q:
            w.write("Key.q")
        elif self == Self.r:
            w.write("Key.r")
        elif self == Self.s:
            w.write("Key.s")
        elif self == Self.t:
            w.write("Key.t")
        elif self == Self.u:
            w.write("Key.u")
        elif self == Self.v:
            w.write("Key.v")
        elif self == Self.w:
            w.write("Key.w")
        elif self == Self.x:
            w.write("Key.x")
        elif self == Self.y:
            w.write("Key.y")
        elif self == Self.z:
            w.write("Key.z")
        elif self == Self.left_bracket:
            w.write("Key.left_bracket")
        elif self == Self.backslash:
            w.write("Key.backslash")
        elif self == Self.right_bracket:
            w.write("Key.right_bracket")
        elif self == Self.grave_accent:
            w.write("Key.grave_accent")
        elif self == Self.world_1:
            w.write("Key.world_1")
        elif self == Self.world_2:
            w.write("Key.world_2")
        elif self == Self.escape:
            w.write("Key.escape")
        elif self == Self.enter:
            w.write("Key.enter")
        elif self == Self.tab:
            w.write("Key.tab")
        elif self == Self.backspace:
            w.write("Key.backspace")
        elif self == Self.insert:
            w.write("Key.insert")
        elif self == Self.delete:
            w.write("Key.delete")
        elif self == Self.right:
            w.write("Key.right")
        elif self == Self.left:
            w.write("Key.left")
        elif self == Self.down:
            w.write("Key.down")
        elif self == Self.up:
            w.write("Key.up")
        elif self == Self.page_up:
            w.write("Key.page_up")
        elif self == Self.page_down:
            w.write("Key.page_down")
        elif self == Self.home:
            w.write("Key.home")
        elif self == Self.end:
            w.write("Key.end")
        elif self == Self.caps_lock:
            w.write("Key.caps_lock")
        elif self == Self.scroll_lock:
            w.write("Key.scroll_lock")
        elif self == Self.num_lock:
            w.write("Key.num_lock")
        elif self == Self.print_screen:
            w.write("Key.print_screen")
        elif self == Self.pause:
            w.write("Key.pause")
        elif self == Self.f1:
            w.write("Key.f1")
        elif self == Self.f2:
            w.write("Key.f2")
        elif self == Self.f3:
            w.write("Key.f3")
        elif self == Self.f4:
            w.write("Key.f4")
        elif self == Self.f5:
            w.write("Key.f5")
        elif self == Self.f6:
            w.write("Key.f6")
        elif self == Self.f7:
            w.write("Key.f7")
        elif self == Self.f8:
            w.write("Key.f8")
        elif self == Self.f9:
            w.write("Key.f9")
        elif self == Self.f10:
            w.write("Key.f10")
        elif self == Self.f11:
            w.write("Key.f11")
        elif self == Self.f12:
            w.write("Key.f12")
        elif self == Self.f13:
            w.write("Key.f13")
        elif self == Self.f14:
            w.write("Key.f14")
        elif self == Self.f15:
            w.write("Key.f15")
        elif self == Self.f16:
            w.write("Key.f16")
        elif self == Self.f17:
            w.write("Key.f17")
        elif self == Self.f18:
            w.write("Key.f18")
        elif self == Self.f19:
            w.write("Key.f19")
        elif self == Self.f20:
            w.write("Key.f20")
        elif self == Self.f21:
            w.write("Key.f21")
        elif self == Self.f22:
            w.write("Key.f22")
        elif self == Self.f23:
            w.write("Key.f23")
        elif self == Self.f24:
            w.write("Key.f24")
        elif self == Self.f25:
            w.write("Key.f25")
        elif self == Self.kp_0:
            w.write("Key.kp_0")
        elif self == Self.kp_1:
            w.write("Key.kp_1")
        elif self == Self.kp_2:
            w.write("Key.kp_2")
        elif self == Self.kp_3:
            w.write("Key.kp_3")
        elif self == Self.kp_4:
            w.write("Key.kp_4")
        elif self == Self.kp_5:
            w.write("Key.kp_5")
        elif self == Self.kp_6:
            w.write("Key.kp_6")
        elif self == Self.kp_7:
            w.write("Key.kp_7")
        elif self == Self.kp_8:
            w.write("Key.kp_8")
        elif self == Self.kp_9:
            w.write("Key.kp_9")
        elif self == Self.kp_decimal:
            w.write("Key.kp_decimal")
        elif self == Self.kp_divide:
            w.write("Key.kp_divide")
        elif self == Self.kp_multiply:
            w.write("Key.kp_multiply")
        elif self == Self.kp_subtract:
            w.write("Key.kp_subtract")
        elif self == Self.kp_add:
            w.write("Key.kp_add")
        elif self == Self.kp_enter:
            w.write("Key.kp_enter")
        elif self == Self.kp_equal:
            w.write("Key.kp_equal")
        elif self == Self.left_shift:
            w.write("Key.left_shift")
        elif self == Self.left_control:
            w.write("Key.left_control")
        elif self == Self.left_alt:
            w.write("Key.left_alt")
        elif self == Self.left_super:
            w.write("Key.left_super")
        elif self == Self.right_shift:
            w.write("Key.right_shift")
        elif self == Self.right_control:
            w.write("Key.right_control")
        elif self == Self.right_alt:
            w.write("Key.right_alt")
        elif self == Self.right_super:
            w.write("Key.right_super")
        elif self == Self.menu:
            w.write("Key.menu")
        elif self == Self.unknown:
            w.write("Key.unknown")
        else:
            w.write("Key(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct Mod(Copyable, EqualityComparable, ImplicitlyCopyable, Movable):
    var _value: Int32
    comptime shift = Self(0x0001)
    comptime control = Self(0x0002)
    comptime alt = Self(0x0004)
    comptime super = Self(0x0008)
    comptime caps_lock = Self(0x0010)
    comptime num_lock = Self(0x0020)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value


@fieldwise_init
struct MouseButton(
    Copyable, EqualityComparable, ImplicitlyCopyable, Movable, Writable
):
    var _value: Int32
    comptime one = Self(_cffi.GLFW_MOUSE_BUTTON_1)
    comptime two = Self(_cffi.GLFW_MOUSE_BUTTON_2)
    comptime three = Self(_cffi.GLFW_MOUSE_BUTTON_3)
    comptime four = Self(_cffi.GLFW_MOUSE_BUTTON_4)
    comptime five = Self(_cffi.GLFW_MOUSE_BUTTON_5)
    comptime six = Self(_cffi.GLFW_MOUSE_BUTTON_6)
    comptime seven = Self(_cffi.GLFW_MOUSE_BUTTON_7)
    comptime eight = Self(_cffi.GLFW_MOUSE_BUTTON_8)
    comptime last = Self(_cffi.GLFW_MOUSE_BUTTON_8)
    comptime left = Self(_cffi.GLFW_MOUSE_BUTTON_1)
    comptime right = Self(_cffi.GLFW_MOUSE_BUTTON_2)
    comptime middle = Self(_cffi.GLFW_MOUSE_BUTTON_3)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        # Prefer semantic names over numeric ones
        if self == Self.left:
            w.write("MouseButton.left")
        elif self == Self.right:
            w.write("MouseButton.right")
        elif self == Self.middle:
            w.write("MouseButton.middle")
        elif self == Self.four:
            w.write("MouseButton.four")
        elif self == Self.five:
            w.write("MouseButton.five")
        elif self == Self.six:
            w.write("MouseButton.six")
        elif self == Self.seven:
            w.write("MouseButton.seven")
        elif self == Self.eight:
            w.write("MouseButton.eight")
        else:
            w.write("MouseButton(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct JoyStick(Copyable, EqualityComparable, ImplicitlyCopyable, Movable):
    var _value: Int32

    comptime one = Self(0)
    comptime two = Self(1)
    comptime three = Self(2)
    comptime four = Self(3)
    comptime five = Self(4)
    comptime six = Self(5)
    comptime seven = Self(6)
    comptime eight = Self(7)
    comptime nine = Self(8)
    comptime ten = Self(9)
    comptime eleven = Self(10)
    comptime twelve = Self(11)
    comptime thirteen = Self(12)
    comptime fourteen = Self(13)
    comptime fifteen = Self(14)
    comptime sixteen = Self(15)
    comptime last = Self.sixteen

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.one:
            w.write("JoyStick.one")
        elif self == Self.two:
            w.write("JoyStick.two")
        elif self == Self.three:
            w.write("JoyStick.three")
        elif self == Self.four:
            w.write("JoyStick.four")
        elif self == Self.five:
            w.write("JoyStick.five")
        elif self == Self.six:
            w.write("JoyStick.six")
        elif self == Self.seven:
            w.write("JoyStick.seven")
        elif self == Self.eight:
            w.write("JoyStick.eight")
        elif self == Self.nine:
            w.write("JoyStick.nine")
        elif self == Self.ten:
            w.write("JoyStick.ten")
        elif self == Self.eleven:
            w.write("JoyStick.eleven")
        elif self == Self.twelve:
            w.write("JoyStick.twelve")
        elif self == Self.thirteen:
            w.write("JoyStick.thirteen")
        elif self == Self.fourteen:
            w.write("JoyStick.fourteen")
        elif self == Self.fifteen:
            w.write("JoyStick.fifteen")
        elif self == Self.sixteen:
            w.write("JoyStick.sixteen")
        else:
            w.write("JoyStick(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct Error(Copyable, EqualityComparable, ImplicitlyCopyable, Movable):
    var _value: Int32

    comptime no_error = Self(0)
    comptime not_initialized = Self(0x00010001)
    comptime no_current_context = Self(0x00010002)
    comptime invalid_enum = Self(0x00010003)
    comptime invalid_value = Self(0x00010004)
    comptime out_of_memory = Self(0x00010005)
    comptime api_unavailable = Self(0x00010006)
    comptime version_unavailable = Self(0x00010007)
    comptime platform_error = Self(0x00010008)
    comptime format_unavailable = Self(0x00010009)
    comptime no_window_context = Self(0x0001000A)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.no_error:
            w.write("Error.no_error")
        elif self == Self.not_initialized:
            w.write("Error.not_initialized")
        elif self == Self.no_current_context:
            w.write("Error.no_current_context")
        elif self == Self.invalid_enum:
            w.write("Error.invalid_enum")
        elif self == Self.invalid_value:
            w.write("Error.invalid_value")
        elif self == Self.out_of_memory:
            w.write("Error.out_of_memory")
        elif self == Self.api_unavailable:
            w.write("Error.api_unavailable")
        elif self == Self.version_unavailable:
            w.write("Error.version_unavailable")
        elif self == Self.platform_error:
            w.write("Error.platform_error")
        elif self == Self.format_unavailable:
            w.write("Error.format_unavailable")
        elif self == Self.no_window_context:
            w.write("Error.no_window_context")
        else:
            w.write("Error(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct GamepadButton(Copyable, EqualityComparable, ImplicitlyCopyable, Movable):
    var _value: Int32

    comptime a = Self(0)
    comptime b = Self(1)
    comptime x = Self(2)
    comptime y = Self(3)
    comptime left_bumper = Self(4)
    comptime right_bumper = Self(5)
    comptime back = Self(6)
    comptime start = Self(7)
    comptime guide = Self(8)
    comptime left_thumb = Self(9)
    comptime right_thumb = Self(10)
    comptime dpad_up = Self(11)
    comptime dpad_right = Self(12)
    comptime dpad_down = Self(13)
    comptime dpad_left = Self(14)
    comptime last = Self.dpad_left
    comptime cross = Self.a
    comptime circle = Self.b
    comptime square = Self.x
    comptime triangle = Self.y

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        # Prefer Xbox naming over PlayStation naming
        if self == Self.a:
            w.write("GamepadButton.a")
        elif self == Self.b:
            w.write("GamepadButton.b")
        elif self == Self.x:
            w.write("GamepadButton.x")
        elif self == Self.y:
            w.write("GamepadButton.y")
        elif self == Self.left_bumper:
            w.write("GamepadButton.left_bumper")
        elif self == Self.right_bumper:
            w.write("GamepadButton.right_bumper")
        elif self == Self.back:
            w.write("GamepadButton.back")
        elif self == Self.start:
            w.write("GamepadButton.start")
        elif self == Self.guide:
            w.write("GamepadButton.guide")
        elif self == Self.left_thumb:
            w.write("GamepadButton.left_thumb")
        elif self == Self.right_thumb:
            w.write("GamepadButton.right_thumb")
        elif self == Self.dpad_up:
            w.write("GamepadButton.dpad_up")
        elif self == Self.dpad_right:
            w.write("GamepadButton.dpad_right")
        elif self == Self.dpad_down:
            w.write("GamepadButton.dpad_down")
        elif self == Self.dpad_left:
            w.write("GamepadButton.dpad_left")
        else:
            w.write("GamepadButton(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct GamepadAxis(Copyable, EqualityComparable, ImplicitlyCopyable, Movable):
    var _value: Int32

    comptime left_x = Self(0)
    comptime left_y = Self(1)
    comptime right_x = Self(2)
    comptime right_y = Self(3)
    comptime left_trigger = Self(4)
    comptime right_trigger = Self(5)
    comptime last = Self.right_trigger

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.left_x:
            w.write("GamepadAxis.left_x")
        elif self == Self.left_y:
            w.write("GamepadAxis.left_y")
        elif self == Self.right_x:
            w.write("GamepadAxis.right_x")
        elif self == Self.right_y:
            w.write("GamepadAxis.right_y")
        elif self == Self.left_trigger:
            w.write("GamepadAxis.left_trigger")
        elif self == Self.right_trigger:
            w.write("GamepadAxis.right_trigger")
        else:
            w.write("GamepadAxis(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct Attribute(Copyable, EqualityComparable, ImplicitlyCopyable, Movable):
    var _value: Int32

    comptime focused = Self(0x00020001)
    comptime iconified = Self(0x00020002)
    comptime resizable = Self(0x00020003)
    comptime visible = Self(0x00020004)
    comptime decorated = Self(0x00020005)
    comptime auto_iconify = Self(0x00020006)
    comptime floating = Self(0x00020007)
    comptime maximized = Self(0x00020008)
    comptime center_cursor = Self(0x00020009)
    comptime transparent_framebuffer = Self(0x0002000A)
    comptime hovered = Self(0x0002000B)
    comptime focus_on_show = Self(0x0002000C)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.focused:
            w.write("Attribute.focused")
        elif self == Self.iconified:
            w.write("Attribute.iconified")
        elif self == Self.resizable:
            w.write("Attribute.resizable")
        elif self == Self.visible:
            w.write("Attribute.visible")
        elif self == Self.decorated:
            w.write("Attribute.decorated")
        elif self == Self.auto_iconify:
            w.write("Attribute.auto_iconify")
        elif self == Self.floating:
            w.write("Attribute.floating")
        elif self == Self.maximized:
            w.write("Attribute.maximized")
        elif self == Self.center_cursor:
            w.write("Attribute.center_cursor")
        elif self == Self.transparent_framebuffer:
            w.write("Attribute.transparent_framebuffer")
        elif self == Self.hovered:
            w.write("Attribute.hovered")
        elif self == Self.focus_on_show:
            w.write("Attribute.focus_on_show")
        else:
            w.write("Attribute(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct FramebufferHint(
    Copyable, EqualityComparable, ImplicitlyCopyable, Movable
):
    var _value: Int32

    comptime red_bits = Self(0x00021001)
    comptime green_bits = Self(0x00021002)
    comptime blue_bits = Self(0x00021003)
    comptime alpha_bits = Self(0x00021004)
    comptime depth_bits = Self(0x00021005)
    comptime stencil_bits = Self(0x00021006)
    comptime accum_red_bits = Self(0x00021007)
    comptime accum_green_bits = Self(0x00021008)
    comptime accum_blue_bits = Self(0x00021009)
    comptime accum_alpha_bits = Self(0x0002100A)
    comptime aux_buffers = Self(0x0002100B)
    comptime stereo = Self(0x0002100C)
    comptime samples = Self(0x0002100D)
    comptime srgb_capable = Self(0x0002100E)
    comptime doublebuffer = Self(0x00021010)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.red_bits:
            w.write("FramebufferHint.red_bits")
        elif self == Self.green_bits:
            w.write("FramebufferHint.green_bits")
        elif self == Self.blue_bits:
            w.write("FramebufferHint.blue_bits")
        elif self == Self.alpha_bits:
            w.write("FramebufferHint.alpha_bits")
        elif self == Self.depth_bits:
            w.write("FramebufferHint.depth_bits")
        elif self == Self.stencil_bits:
            w.write("FramebufferHint.stencil_bits")
        elif self == Self.accum_red_bits:
            w.write("FramebufferHint.accum_red_bits")
        elif self == Self.accum_green_bits:
            w.write("FramebufferHint.accum_green_bits")
        elif self == Self.accum_blue_bits:
            w.write("FramebufferHint.accum_blue_bits")
        elif self == Self.accum_alpha_bits:
            w.write("FramebufferHint.accum_alpha_bits")
        elif self == Self.aux_buffers:
            w.write("FramebufferHint.aux_buffers")
        elif self == Self.stereo:
            w.write("FramebufferHint.stereo")
        elif self == Self.samples:
            w.write("FramebufferHint.samples")
        elif self == Self.srgb_capable:
            w.write("FramebufferHint.srgb_capable")
        elif self == Self.doublebuffer:
            w.write("FramebufferHint.doublebuffer")
        else:
            w.write("FramebufferHint(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct MonitorHint(Copyable, EqualityComparable, ImplicitlyCopyable, Movable):
    var _value: Int32
    comptime refresh_rate = Self(0x0002100F)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.refresh_rate:
            w.write("MonitorHint.refresh_rate")


@fieldwise_init
struct ContextHint(Copyable, EqualityComparable, ImplicitlyCopyable, Movable):
    var _value: Int32

    comptime client_api = Self(0x00022001)
    comptime context_version_major = Self(0x00022002)
    comptime context_version_minor = Self(0x00022003)
    comptime context_revision = Self(0x00022004)
    comptime context_robustness = Self(0x00022005)
    comptime opengl_forward_compat = Self(0x00022006)
    comptime opengl_debug_context = Self(0x00022007)
    comptime opengl_profile = Self(0x00022008)
    comptime context_release_behavior = Self(0x00022009)
    comptime context_no_error = Self(0x0002200A)
    comptime context_creation_api = Self(0x0002200B)
    comptime scale_to_monitor = Self(0x0002200C)
    comptime cocoa_retina_framebuffer = Self(0x00023001)
    comptime cocoa_frame_name = Self(0x00023002)
    comptime cocoa_graphics_switching = Self(0x00023003)
    comptime x11_class_name = Self(0x00024001)
    comptime x11_instance_name = Self(0x00024002)
    comptime no_api = Self(0)
    comptime opengl_api = Self(0x00030001)
    comptime opengl_es_api = Self(0x00030002)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.client_api:
            w.write("ContextHint.client_api")
        elif self == Self.context_version_major:
            w.write("ContextHint.context_version_major")
        elif self == Self.context_version_minor:
            w.write("ContextHint.context_version_minor")
        elif self == Self.context_revision:
            w.write("ContextHint.context_revision")
        elif self == Self.context_robustness:
            w.write("ContextHint.context_robustness")
        elif self == Self.opengl_forward_compat:
            w.write("ContextHint.opengl_forward_compat")
        elif self == Self.opengl_debug_context:
            w.write("ContextHint.opengl_debug_context")
        elif self == Self.opengl_profile:
            w.write("ContextHint.opengl_profile")
        elif self == Self.context_release_behavior:
            w.write("ContextHint.context_release_behavior")
        elif self == Self.context_no_error:
            w.write("ContextHint.context_no_error")
        elif self == Self.context_creation_api:
            w.write("ContextHint.context_creation_api")
        elif self == Self.scale_to_monitor:
            w.write("ContextHint.scale_to_monitor")
        elif self == Self.cocoa_retina_framebuffer:
            w.write("ContextHint.cocoa_retina_framebuffer")
        elif self == Self.cocoa_frame_name:
            w.write("ContextHint.cocoa_frame_name")
        elif self == Self.cocoa_graphics_switching:
            w.write("ContextHint.cocoa_graphics_switching")
        elif self == Self.x11_class_name:
            w.write("ContextHint.x11_class_name")
        elif self == Self.x11_instance_name:
            w.write("ContextHint.x11_instance_name")
        elif self == Self.no_api:
            w.write("ContextHint.no_api")
        elif self == Self.opengl_api:
            w.write("ContextHint.opengl_api")
        elif self == Self.opengl_es_api:
            w.write("ContextHint.opengl_es_api")
        else:
            w.write("ContextHint(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct ContextRobustness(
    Copyable, EqualityComparable, ImplicitlyCopyable, Movable
):
    var _value: Int32

    comptime no_robustness = Self(0)
    comptime no_reset_notification = Self(0x00031001)
    comptime lose_context_on_reset = Self(0x00031002)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.no_robustness:
            w.write("ContextRobustness.no_robustness")
        elif self == Self.no_reset_notification:
            w.write("ContextRobustness.no_reset_notification")
        elif self == Self.lose_context_on_reset:
            w.write("ContextRobustness.lose_context_on_reset")
        else:
            w.write("ContextRobustness(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct OpenGLProfile(Copyable, EqualityComparable, ImplicitlyCopyable, Movable):
    var _value: Int32

    comptime any_profile = Self(0)
    comptime core_profile = Self(0x00032001)
    comptime compat_profile = Self(0x00032002)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.any_profile:
            w.write("OpenGLProfile.any_profile")
        elif self == Self.core_profile:
            w.write("OpenGLProfile.core_profile")
        elif self == Self.compat_profile:
            w.write("OpenGLProfile.compat_profile")
        else:
            w.write("OpenGLProfile(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct InputMode(Copyable, EqualityComparable, ImplicitlyCopyable, Movable):
    var _value: Int32

    comptime cursor = Self(0x00033001)
    comptime sticky_keys = Self(0x00033002)
    comptime sticky_mouse_buttons = Self(0x00033003)
    comptime lock_key_mods = Self(0x00033004)
    comptime raw_mouse_motion = Self(0x00033005)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.cursor:
            w.write("InputMode.cursor")
        elif self == Self.sticky_keys:
            w.write("InputMode.sticky_keys")
        elif self == Self.sticky_mouse_buttons:
            w.write("InputMode.sticky_mouse_buttons")
        elif self == Self.lock_key_mods:
            w.write("InputMode.lock_key_mods")
        elif self == Self.raw_mouse_motion:
            w.write("InputMode.raw_mouse_motion")
        else:
            w.write("InputMode(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct CursorMode(Copyable, EqualityComparable, ImplicitlyCopyable, Movable):
    var _value: Int32

    comptime normal = Self(0x00034001)
    comptime hidden = Self(0x00034002)
    comptime disabled = Self(0x00034003)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.normal:
            w.write("CursorMode.normal")
        elif self == Self.hidden:
            w.write("CursorMode.hidden")
        elif self == Self.disabled:
            w.write("CursorMode.disabled")
        else:
            w.write("CursorMode(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct ContextReleaseBehavior(
    Copyable, EqualityComparable, ImplicitlyCopyable, Movable
):
    var _value: Int32

    comptime any_release_behavior = Self(0)
    comptime release_behavior_flush = Self(0x00035001)
    comptime release_behavior_none = Self(0x00035002)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.any_release_behavior:
            w.write("ContextReleaseBehavior.any_release_behavior")
        elif self == Self.release_behavior_flush:
            w.write("ContextReleaseBehavior.release_behavior_flush")
        elif self == Self.release_behavior_none:
            w.write("ContextReleaseBehavior.release_behavior_none")
        else:
            w.write("ContextReleaseBehavior(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct ContextCreationApi(
    Copyable, EqualityComparable, ImplicitlyCopyable, Movable
):
    var _value: Int32

    comptime native_context_api = Self(0x00036001)
    comptime egl_context_api = Self(0x00036002)
    comptime osmesa_context_api = Self(0x00036003)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.native_context_api:
            w.write("ContextCreationApi.native_context_api")
        elif self == Self.egl_context_api:
            w.write("ContextCreationApi.egl_context_api")
        elif self == Self.osmesa_context_api:
            w.write("ContextCreationApi.osmesa_context_api")
        else:
            w.write("ContextCreationApi(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct WaylandHints(Copyable, EqualityComparable, ImplicitlyCopyable, Movable):
    var _value: Int32

    comptime prefer_libdecor = Self(0x00038001)
    comptime disable_libdecor = Self(0x00038002)
    comptime libdecor = Self(0x00053001)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.prefer_libdecor:
            w.write("WaylandHints.prefer_libdecor")
        elif self == Self.disable_libdecor:
            w.write("WaylandHints.disable_libdecor")
        elif self == Self.libdecor:
            w.write("WaylandHints.libdecor")
        else:
            w.write("WaylandHints(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct CursorShape(Copyable, EqualityComparable, ImplicitlyCopyable, Movable):
    var _value: Int32

    comptime arrow = Self(0x00036001)
    comptime ibeam = Self(0x00036002)
    comptime crosshair = Self(0x00036003)
    comptime hand = Self(0x00036004)
    comptime hresize = Self(0x00036005)
    comptime vresize = Self(0x00036006)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.arrow:
            w.write("CursorShape.arrow")
        elif self == Self.ibeam:
            w.write("CursorShape.ibeam")
        elif self == Self.crosshair:
            w.write("CursorShape.crosshair")
        elif self == Self.hand:
            w.write("CursorShape.hand")
        elif self == Self.hresize:
            w.write("CursorShape.hresize")
        elif self == Self.vresize:
            w.write("CursorShape.vresize")
        else:
            w.write("CursorShape(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct MonitorEvent(Copyable, EqualityComparable, ImplicitlyCopyable, Movable):
    var _value: Int32
    comptime connected = Self(0x00040001)
    comptime disconnected = Self(0x00040002)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.connected:
            w.write("CursorShape.connected")
        elif self == Self.disconnected:
            w.write("CursorShape.disconnected")


@fieldwise_init
struct SharedInitHints(
    Copyable, EqualityComparable, ImplicitlyCopyable, Movable
):
    var _value: Int32

    comptime joystick_hat_buttons = Self(0x00050001)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.joystick_hat_buttons:
            w.write("SharedInitHints.joystick_hat_buttons")
        else:
            w.write("SharedInitHints(")
            w.write(self._value)
            w.write(")")


@fieldwise_init
struct MacOSHints(Copyable, EqualityComparable, ImplicitlyCopyable, Movable):
    var _value: Int32

    comptime cocoa_chdir_resources = Self(0x00051001)
    comptime cocoa_menubar = Self(0x00051002)

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value

    fn write_to(self, mut w: Some[Writer]):
        if self == Self.cocoa_chdir_resources:
            w.write("MacOSHints.cocoa_chdir_resources")
        elif self == Self.cocoa_menubar:
            w.write("MacOSHints.cocoa_menubar")
        else:
            w.write("MacOSHints(")
            w.write(self._value)
            w.write(")")
