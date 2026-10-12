#!/bin/bash
# Link the custom app into the NuttX apps tree and configure the build.
set -e
top=$(cd "$(dirname "$0")" && pwd)
ln -sfn "$top/myhello" "$top/nuttxspace/apps/myhello"
cd "$top/nuttxspace/nuttx"
make distclean || rm -f .config Make.defs
./tools/configure.sh esp32c6-xiao:usbnsh
kconfig-tweak --file .config -e MYHELLO || true
make olddefconfig
