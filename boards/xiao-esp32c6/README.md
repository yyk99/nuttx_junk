# Seeed XIAO ESP32C6

NuttX config `esp32c6-xiao:usbnsh`. `myhello` blinks the user LED (GPIO15, active
low) and starts at boot.

## Toolchain

Use Espressif's `riscv32-esp-elf` GCC (the apt `gcc-riscv64-unknown-elf` has no libc
headers and fails with `sys/lock.h: No such file or directory`). It is about 290 MB:

    mkdir -p ~/tools && cd ~/tools
    gh release download esp-14.2.0_20260121 -R espressif/crosstool-NG \
        -p "riscv32-esp-elf-14.2.0_20260121-x86_64-linux-gnu.tar.xz"
    tar xf riscv32-esp-elf-14.2.0_20260121-x86_64-linux-gnu.tar.xz
    export PATH=$HOME/tools/riscv32-esp-elf/bin:$PATH

Without `gh`, download the same file from
https://github.com/espressif/crosstool-NG/releases/tag/esp-14.2.0_20260121.
If you have the Arduino ESP32 core installed, its copy also works:
`$HOME/.arduino15/packages/esp32/tools/esp-rv32/2601/bin`.

Check: `riscv32-esp-elf-gcc --version` and `esptool.py version` (needs the venv).

## Build and flash (Make)

    ./setup.sh xiao-esp32c6
    cd nuttxspace/nuttx
    make -j CROSSDEV=riscv32-esp-elf-

Flash (board on `/dev/ttyACM0`; you need to be in the `dialout` group):

    make flash CROSSDEV=riscv32-esp-elf- ESPTOOL_PORT=/dev/ttyACM0 ESPTOOL_BINDIR=./

Simple Boot is used, so no separate bootloader is needed (image is written at 0x0).

## Run

Open the console with `screen`. Close it before flashing again.

    screen /dev/ttyACM0 115200

Press Enter (or reset the board) to get the prompt, then run the app. It blinks
the user LED 10 times by default; pass a count to change that:

    nsh> myhello 5
    Hello from myhello! Blinking LED 5 times

To restart the board from the prompt (the USB port drops and returns, so reconnect
`screen` afterwards):

    nsh> reboot

To leave `screen`, press Ctrl-A then `\` (and confirm with `y`), or Ctrl-A then
`k`. Just closing the terminal leaves the session holding the port; list it with
`screen -ls` and remove it with `screen -X -S <session> quit`.
`picocom -b 115200 /dev/ttyACM0` (exit with Ctrl-A Ctrl-X) also works.

## Build with CMake

    sudo apt install -y cmake ninja-build
    ./setup.sh xiao-esp32c6 cmake

The output goes to `nuttxspace/build/` (the first run takes about 5 minutes because it
fetches the ESP HAL). Flash it (this does not use `make flash`):

    esptool.py --chip esp32c6 -p /dev/ttyACM0 -b 921600 write_flash 0x0 nuttxspace/build/nuttx.bin

`patches/cmake/cmake-esp-toolchain.patch` teaches NuttX's CMake the `riscv32-esp-elf`
compiler prefix (it only knows `riscv-none-elf` and `riscv64-unknown-elf`). CMake
refuses an in-tree `.config`, so `setup.sh` runs `make distclean`; run
`./setup.sh xiao-esp32c6` again to go back to the Make build.

## Patches

- `xiao-led-gpio15.patch` - routes the board GPIO output (`/dev/gpio0`) to the user LED.
- `rcs-autostart-myhello.patch` - runs `myhello &` from `etc/init.d/rcS`.
- `cmake/cmake-esp-toolchain.patch` - CMake toolchain prefix (CMake mode only).

## Autostart at boot

`myhello` starts automatically after reset: `board.conf` enables the `/etc` ROMFS and
the `rcS` patch runs `myhello &`. The boot log shows `rcS file is called!`, the LED
blinks 10 times, and the NSH prompt stays available (`ps` lists the `myhello` task).
To disable, delete `patches/rcs-autostart-myhello.patch` and the `-e FS_ROMFS -e ETC_ROMFS`
options from `board.conf`.

## Notes

- The board may disappear from `/dev/ttyACM0` after a crash or reflash; replug it (hold
  BOOT for download mode).
- Stock sample without myhello: `make distclean`, `./tools/configure.sh esp32c6-xiao:usbnsh`,
  `make -j CROSSDEV=riscv32-esp-elf-` in `nuttxspace/nuttx` (includes the `hello` command).

See also https://wiki.seeedstudio.com/xiao_esp32c6_nuttx/
