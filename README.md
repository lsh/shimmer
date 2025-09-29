# Shimmer

This repository is a place for me to experiment with rendering buffers from Mojo into OpenGL textures. It is currently not optimized, and the bindings are sparse. Eventually it might be worth using `cuda_gl_interop` / HIP runtime OpenGL interop / Metal OpenGL `CVPixelBufferObject` interop to speed things up, but for now I'm not doing anything particularly expensive.
