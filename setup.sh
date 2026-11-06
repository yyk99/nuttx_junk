#!/bin/bash
# Link the custom app into the NuttX apps tree and configure NuttX for a board.
# Usage: ./setup.sh <board> [make|cmake]     (boards: see boards/)
set -e
top=$(cd "$(dirname "$0")" && pwd)
board=$1
mode=${2:-make}
if [ ! -f "$top/boards/$board/board.conf" ] || [ "$mode" != make -a "$mode" != cmake ]; then
    echo "Usage: $0 <board> [make|cmake]" >&2
    echo "Boards: $(cd "$top/boards" && ls | tr '\n' ' ')" >&2
    exit 1
fi
boarddir=$top/boards/$board
. "$boarddir/board.conf"    # NUTTX_CONFIG, CROSSDEV, KCONFIG_TWEAKS

# NuttX's Make and CMake builds both pick up apps/external automatically
rm -f "$top/nuttxspace/apps/myhello"
ln -sfn "$top/myhello" "$top/nuttxspace/apps/external"
cd "$top/nuttxspace/nuttx"

# Drop patches left by a previously configured board
git checkout -q .
# CMake refuses an in-tree .config left over from a Make build
make distclean || rm -f .config Make.defs

patches=$(ls "$boarddir"/patches/*.patch 2>/dev/null || true)
[ "$mode" = cmake ] && patches="$patches $(ls "$boarddir"/patches/cmake/*.patch 2>/dev/null || true)"
for p in $patches; do
    echo "Applying $(basename "$p")"
    git apply "$p"
done

if [ "$mode" = make ]; then
    ./tools/configure.sh "$NUTTX_CONFIG"
    kconfig-tweak --file .config $KCONFIG_TWEAKS
    make olddefconfig
    echo "Next: cd nuttxspace/nuttx && make -j CROSSDEV=$CROSSDEV"
else
    rm -rf ../build
    cmake -S . -B ../build -GNinja -DBOARD_CONFIG="$NUTTX_CONFIG"
    kconfig-tweak --file ../build/.config $KCONFIG_TWEAKS
    ninja -C ../build olddefconfig
    ninja -C ../build
    echo "Image: $top/nuttxspace/build/nuttx.bin"
fi
