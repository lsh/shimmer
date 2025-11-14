#!/bin/bash
set -e

# Build the project
mojo build main.mojo -o build/main

# Fix wgpu_native library path
OLD_PATH=$(otool -L build/main | grep wgpu_native | awk '{print $1}' | xargs || echo "")
if [ ! -z "$OLD_PATH" ]; then
  install_name_tool -change "$OLD_PATH" @rpath/libwgpu_native.dylib build/main
fi

# Add rpath
install_name_tool -add_rpath @loader_path/../.pixi/envs/default/lib build/main 2>/dev/null || true

echo "✓ Build complete: build/main"
