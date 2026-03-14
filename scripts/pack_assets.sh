#!/bin/bash
# pack_assets.sh — pack web application assets into a zip for embedding
# Phase D: used before compilation to create webapp.zip
# Usage: ./scripts/pack_assets.sh <assets_dir> <output_zip>
#
# Example:
#   ./scripts/pack_assets.sh dist/ src/webapp.zip
#
# After running, recompile src/main.pb so IncludeBinary picks up the new zip.

set -e

ASSETS_DIR="${1:?Usage: pack_assets.sh <assets_dir> <output_zip>}"
OUTPUT_ZIP="${2:?Usage: pack_assets.sh <assets_dir> <output_zip>}"

echo "Packing assets from: $ASSETS_DIR"
echo "Output zip: $OUTPUT_ZIP"

cd "$ASSETS_DIR"
zip -r "$OUTPUT_ZIP" . --exclude "*.DS_Store" --exclude "__MACOSX/*"

echo "Done: $(du -sh "$OUTPUT_ZIP" | cut -f1) written to $OUTPUT_ZIP"
