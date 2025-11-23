alias OPENGL_TO_WGPU_MATRIX = Mat4(
    {1.0, 0.0, 0.0, 0.0},
    {0.0, 1.0, 0.0, 0.0},
    {0.0, 0.0, 0.5, 0.0},
    {0.0, 0.0, 0.5, 1.0},
)


@fieldwise_init
struct Camera(Copyable, Movable):
    var eye: Point3
    var target: Point3
    var up: Vec3
    var aspect: Float32
    var fovy: Float32
    var znear: Float32
    var zfar: Float32

    fn build_view_projection_matrix(self) -> Mat4:
        var view = Mat4.look_at_rh(self.eye, self.target, self.up)
        var proj = Mat4.perspective_rh(
            self.fovy, self.aspect, self.znear, self.zfar
        )

        return OPENGL_TO_WGPU_MATRIX * proj * view
