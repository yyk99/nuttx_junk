#!/bin/bash
# Link the custom app into the NuttX apps tree and configure the build.
set -e
top=$(cd "$(dirname "$0")" && pwd)
ln -sfn "$top/myhello" "$top/nuttxspace/apps/myhello"
cd "$top/nuttxspace/nuttx"
git checkout boards/risc-v/esp32c6/esp32c6-xiao/src/esp32c6_gpio.c \
    boards/risc-v/esp32c6/common/src/etc/init.d/rcS
make distclean || rm -f .config Make.defs
./tools/configure.sh esp32c6-xiao:usbnsh
# Route the board's GPIO output (/dev/gpio0) to the user LED on GPIO15
git apply "$top/patches/xiao-led-gpio15.patch"
# Run myhello from the NSH startup script (/etc/init.d/rcS) at boot
git apply "$top/patches/rcs-autostart-myhello.patch"
kconfig-tweak --file .config -e MYHELLO -e DEV_GPIO -e ESPRESSIF_GPIO_IRQ \
    -e FS_ROMFS -e ETC_ROMFS
make olddefconfig
