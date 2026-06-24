#!/usr/bin/env bash
#
# package-plugin.sh
#
# Creates a ready-to-upload zip of the Dungeon Crawler 3D plugin for the
# Godot Asset Store.  The archive preserves the addons/ tree so users
# simply unzip it into their Godot project root.
#
# Usage:
#   ./scripts/package-plugin.sh            # uses the current commit as label
#   ./scripts/package-plugin.sh v1.2.3      # explicit version label
#
# Output:
#   dist/dungeon_crawler_3d-<version>.zip
#
# Requires: git, and one of: zip, 7z, bsdtar

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_DIR="addons/dungeon_crawler_3d"
PLUGIN_LICENSE="${PLUGIN_DIR}/LICENSE"

# --- Version label -----------------------------------------------------------

LABEL="${1:-$(git -C "$ROOT_DIR" describe --tags --always 2>/dev/null || echo "dev")}"
BASENAME="dungeon_crawler_3d-${LABEL}"

OUTDIR="${ROOT_DIR}/dist"
OUTFILE="${OUTDIR}/${BASENAME}.zip"

mkdir -p "$OUTDIR"

if [[ ! -f "${ROOT_DIR}/${PLUGIN_LICENSE}" ]]; then
    echo "❌ Missing ${PLUGIN_LICENSE}; the Godot Asset Store package must include a license file inside the addon folder."
    exit 1
fi

# --- Detect archive tool -----------------------------------------------------

ARCHIVE_CMD=""
ZIP_OPTS=()

if command -v zip &>/dev/null; then
    ARCHIVE_CMD="zip"
    ZIP_OPTS=("--quiet" "--recurse-paths" "--symlinks")
elif command -v 7z &>/dev/null; then
    ARCHIVE_CMD="7z"
    ZIP_OPTS=("a" "-tzip" "-bsp1" "-bso1")
elif command -v bsdtar &>/dev/null; then
    ARCHIVE_CMD="bsdtar"
    ZIP_OPTS=("acf")
fi

if [[ -z "$ARCHIVE_CMD" ]]; then
    echo "❌ No archive tool found. Install one of: zip, 7z, bsdtar"
    exit 1
fi

# --- Package -----------------------------------------------------------------

cd "$ROOT_DIR"

echo "→ Packaging plugin as ${OUTFILE} …"

case "$ARCHIVE_CMD" in
    zip)
        zip "${ZIP_OPTS[@]}" "$OUTFILE" "$PLUGIN_DIR" \
            --include "${PLUGIN_DIR}/*" \
            --exclude "${PLUGIN_DIR}/.gitkeep"
        ;;
    7z)
        # 7z automatically descends into subdirectories
        7z "${ZIP_OPTS[@]}" "$OUTFILE" "$PLUGIN_DIR" >/dev/null
        ;;
    bsdtar)
        bsdtar "${ZIP_OPTS[@]}" "$OUTFILE" "$PLUGIN_DIR"
        ;;
esac

echo "✓ Done  ($(du -h "$OUTFILE" | cut -f1))"
