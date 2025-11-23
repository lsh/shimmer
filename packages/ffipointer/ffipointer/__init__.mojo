@register_passable("trivial")
struct FFIPointer[type: AnyType, /, *, mut: Bool](
    Defaultable, ImplicitlyBoolable, ImplicitlyCopyable, Movable, Writable
):
    var _value: UnsafePointer[type, Origin[mut].external]

    @always_inline
    fn __init__(out self):
        """Create a null ffi pointer."""
        self._value = {}

    @always_inline
    @implicit
    fn __init__(
        out self: FFIPointer[type, mut=True],
        unsafe_pointer: UnsafePointer[mut=True, type],
    ):
        """Create a mutable ffi pointer from a mutable `UnsafePointer`.

        Args:
            unsafe_pointer: The mutable `UnsafePointer` to convert from.
        """
        self._value = unsafe_pointer.unsafe_origin_cast[MutOrigin.external]()

    @always_inline
    @implicit
    fn __init__(
        out self: FFIPointer[type, mut=False],
        unsafe_pointer: UnsafePointer[type],
    ):
        """Create an immutable ffi pointer from an `UnsafePointer`.

        Args:
            unsafe_pointer: The `UnsafePointer` to convert from.
        """
        self._value = unsafe_pointer.as_immutable().unsafe_origin_cast[
            ImmutOrigin.external
        ]()

    @doc_private
    @implicit
    fn __init__(
        out self: FFIPointer[type, mut=True],
        unsafe_pointer: UnsafePointer[mut=False, type],
    ):
        constrained[
            False,
            (
                "Invalid conversion from immutable `UnsafePointer` to mutable"
                " `FFIPointer`"
            ),
        ]()
        self = {}

    @always_inline
    fn __bool__(self) -> Bool:
        """Return true if the pointer is non-null.

        Returns:
            Whether the pointer is null.
        """
        return Bool(self._value)

    @no_inline
    fn write_to(self, mut writer: Some[Writer]):
        """Formats the pointer to the provided `Writer`.

        Args:
            writer: The `Writer` to format the pointer to.
        """
        self._value.write_to(writer)

    @always_inline
    fn unsafe_ptr(self) -> UnsafePointer[Self.type, Origin[Self.mut].external]:
        return self._value.mut_cast[Self.mut]().unsafe_origin_cast[
            Origin[Self.mut].external
        ]()
