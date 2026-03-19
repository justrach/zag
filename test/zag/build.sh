#!/bin/bash
# Build zag test binaries using system zig (which needs .zig extensions).
# Copies .zag → .zig, builds, cleans up.
set -e

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ZAG_LIB="$ROOT/lib/std"
ZAG_TEST="$ROOT/test/zag"
BUILD_DIR="/tmp/zag_build"

mkdir -p "$BUILD_DIR/lib/std/zag" "$BUILD_DIR/test/zag"

# Copy .zag → .zig
for f in "$ZAG_LIB"/zag.zag; do
    cp "$f" "$BUILD_DIR/lib/std/$(basename "${f%.zag}.zig")"
done
for f in "$ZAG_LIB"/zag/*.zag; do
    cp "$f" "$BUILD_DIR/lib/std/zag/$(basename "${f%.zag}.zig")"
done
for f in "$ZAG_TEST"/*.zag; do
    cp "$f" "$BUILD_DIR/test/zag/$(basename "${f%.zag}.zig")"
done

# Fix imports: .zag → .zig
find "$BUILD_DIR" -name "*.zig" -exec sed -i '' 's/\.zag"/\.zig"/g' {} \;

TARGET="${1:-http_bench}"
OPT="${2:-ReleaseFast}"

echo "Building $TARGET ($OPT)..."
zig build-exe \
    --dep zag \
    -Mroot="$BUILD_DIR/test/zag/${TARGET}.zig" \
    -Mzag="$BUILD_DIR/lib/std/zag.zig" \
    -O "$OPT" \
    -femit-bin="/tmp/zag_${TARGET}"

echo "Built: /tmp/zag_${TARGET}"
