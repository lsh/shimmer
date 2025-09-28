from sys.ffi import external_call


fn glad_load_gl():
    _ = external_call["gladLoadGL", NoneType]()


fn glad_load_gl_loader(
    loader: fn (UnsafePointer[Int8]) -> OpaquePointer,
) -> Int32:
    return external_call["gladLoadGLLoader", Int32](loader)
