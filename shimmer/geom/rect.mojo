@fieldwise_init
struct Rect[dtype: DType = DType.float32](
    Copyable, ImplicitlyCopyable, Movable
):
    """
    Defines a Rectangle's bounds across the x and y axes.
    """

    var x: InlineArray[Scalar[Self.dtype], 2]
    """
    The start and end positions of the Rectangle on the x axis.
    """
    var y: InlineArray[Scalar[Self.dtype], 2]
    """
    The start and end positions of the Rectangle on the y axis.
    """

    fn __init__(
        out self, *, width: Scalar[Self.dtype], height: Scalar[Self.dtype]
    ):
        self.x = [Scalar[Self.dtype](0), Scalar[Self.dtype](0)]
        self.y = [width, height]


@fieldwise_init
struct Padding[dtype: DType = DType.float32](Copyable, Movable):
    """
    The distance between the inner edge of a border and the outer edge of the inner content.
    """

    var x: InlineArray[Scalar[Self.dtype], 2]
    """
    Padding on the start and end of the *x* axis.
    """
    var y: InlineArray[Scalar[Self.dtype], 2]
    """
    Padding on the start and end of the *y* axis.
    """

    @staticmethod
    fn none() -> Self:
        alias zero = Scalar[Self.dtype](0)
        return Self([zero, zero], [zero, zero])


@fieldwise_init
struct Corner(Copyable, Equatable, ImplicitlyCopyable, Movable):
    """
    Either of the four corners of a **Rect**."""

    var _value: UInt32
    alias top_left = Self(0)
    """
    The top left corner of a **Rect**.
    """
    alias top_right = Self(1)
    """
    The top right corner of a **Rect**.
    """
    alias bottom_left = Self(2)
    """
    The bottom left corner of a **Rect**.
    """
    alias bottom_right = Self(3)
    """
    The bottom right corner of a **Rect**.
    """

    fn __eq__(self, rhs: Self) -> Bool:
        return self._value == rhs._value
