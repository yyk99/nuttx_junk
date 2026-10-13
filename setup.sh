#!/bin/bash
# Link the custom app into the NuttX apps tree and configure the build.
set -e
top=$(cd "$(dirname "$0")" && pwd)
ln -sfn "$top/myhello" "$top/nuttxspace/apps/myhello"
cd "$top/nuttxspace/nuttx"
git checkout boards/risc-v/esp32c6/esp32c6-xiao/src/esp32c6_gpio.c
make distclean || rm -f .config Make.defs
./tools/configure.sh esp32c6-xiao:usbnsh
# Route the board's GPIO output (/dev/gpio0) to the user LED on GPIO15
git apply "$top/patches/xiao-led-gpio15.patch"
kconfig-tweak --file .config -e MYHELLO -e DEV_GPIO -e ESPRESSIF_GPIO_IRQ
make olddefconfig
