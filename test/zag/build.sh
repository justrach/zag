#!/bin/bash
# Build zag test binaries using system zig (which needs .zig extensions).
# Copies .zag → .zig, builds, cleans up.
set -e

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ZAG_LIB="$ROOT/lib/std"
ZAG_TEST="$ROOT/test/zag"
BUILD_DIR="/tmp/zag_build"

mkdir -p "$BUILD_DIR/lib/std/zag"

# Copy .zag → .zig (lib)
cp "$ZAG_LIB/zag.zag" "$BUILD_DIR/lib/std/zag.zig"
for f in "$ZAG_LIB"/zag/*.zag; do
    cp "$f" "$BUILD_DIR/lib/std/zag/$(basename "${f%.zag}.zig")"
done

# Copy .zag → .zig (tests, including subdirs)
(cd "$ZAG_TEST" && find . -name "*.zag" -type f) | while read -r rel; do
    src="$ZAG_TEST/$rel"
    dst="$BUILD_DIR/test/zag/${rel%.zag}.zig"
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
done

# Fix imports: .zag → .zig
find "$BUILD_DIR" -name "*.zig" -exec sed -i '' 's/\.zag"/\.zig"/g' {} \;

TARGET="${1:-http_bench}"
OPT="${2:-ReleaseFast}"
OUTNAME=$(echo "$TARGET" | tr '/' '_')

# Create subdirs in build dir if needed
mkdir -p "$(dirname "$BUILD_DIR/test/zag/${TARGET}.zig")"

echo "Building $TARGET ($OPT)..."
zig build-exe \
    --dep zag \
    -Mroot="$BUILD_DIR/test/zag/${TARGET}.zig" \
    -Mzag="$BUILD_DIR/lib/std/zag.zig" \
    -O "$OPT" \
    -femit-bin="/tmp/zag_${OUTNAME}"

echo "Built: /tmp/zag_${OUTNAME}"
