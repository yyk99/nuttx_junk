#!/bin/bash
# CMake/Ninja build of NuttX + myhello for the XIAO ESP32C6 (build dir: nuttxspace/build).
# Needs on PATH: riscv32-esp-elf toolchain, cmake, ninja; in the active venv: esptool, kconfiglib.
set -e
top=$(cd "$(dirname "$0")" && pwd)
# NuttX's CMake picks up apps/external automatically
rm -f "$top/nuttxspace/apps/myhello"
ln -sfn "$top/myhello" "$top/nuttxspace/apps/external"
cd "$top/nuttxspace/nuttx"
git checkout boards/risc-v/esp32c6/esp32c6-xiao/src/esp32c6_gpio.c \
    boards/risc-v/esp32c6/common/src/etc/init.d/rcS \
    arch/risc-v/src/cmake/Toolchain.cmake
# CMake refuses an in-tree .config left over from the Make build
make distclean || rm -f .config Make.defs
git apply "$top/patches/xiao-led-gpio15.patch"
git apply "$top/patches/rcs-autostart-myhello.patch"
git apply "$top/patches/cmake-esp-toolchain.patch"
rm -rf ../build
cmake -S . -B ../build -GNinja -DBOARD_CONFIG=esp32c6-xiao:usbnsh
kconfig-tweak --file ../build/.config -e MYHELLO -e DEV_GPIO -e ESPRESSIF_GPIO_IRQ \
    -e FS_ROMFS -e ETC_ROMFS
ninja -C ../build olddefconfig
ninja -C ../build
echo "Image: $top/nuttxspace/build/nuttx.bin"
