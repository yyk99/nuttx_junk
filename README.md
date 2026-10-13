# Apache NuttX primer and examples

Minimal NuttX setup for the Seeed XIAO ESP32C6, with a custom `myhello` app.

## Install requirements

Packages (Ubuntu/Debian):

    sudo apt install -y bison flex gperf libncurses5-dev libgmp-dev libmpc-dev libmpfr-dev binutils-dev
    sudo apt install -y kconfig-frontends-nox genromfs screen python3-venv

esptool: NuttX needs `esptool.py` >= 4.8, but apt only has 4.7 (installed as
`esptool`). Install a current one in a Python venv at the repo root (it provides
`esptool.py`) and activate it in every shell you build from:

    python3 -m venv .venv
    .venv/bin/pip install esptool
    source .venv/bin/activate

Toolchain: use Espressif's `riscv32-esp-elf` GCC (the apt `gcc-riscv64-unknown-elf`
has no libc headers and fails with `sys/lock.h: No such file or directory`).
Download and unpack it (about 290 MB; verified with this version on x86_64 Linux):

    mkdir -p ~/tools && cd ~/tools
    gh release download esp-14.2.0_20260121 -R espressif/crosstool-NG \
        -p "riscv32-esp-elf-14.2.0_20260121-x86_64-linux-gnu.tar.xz"
    tar xf riscv32-esp-elf-14.2.0_20260121-x86_64-linux-gnu.tar.xz
    export PATH=$HOME/tools/riscv32-esp-elf/bin:$PATH

Without `gh`, download the same file from
https://github.com/espressif/crosstool-NG/releases/tag/esp-14.2.0_20260121.
If you have the Arduino ESP32 core installed, its copy also works:
`$HOME/.arduino15/packages/esp32/tools/esp-rv32/2601/bin`.

Check: `riscv32-esp-elf-gcc --version` and `esptool.py version`.

Get the sources (from the root of this repo; `nuttxspace/` is git-ignored):

    mkdir nuttxspace
    git clone --depth=1 https://github.com/apache/nuttx.git nuttxspace/nuttx
    git clone --depth=1 https://github.com/apache/nuttx-apps nuttxspace/apps

## Build and flash the myhello app

The app lives in `myhello/` (outside the NuttX tree). `setup.sh` symlinks it
into `nuttxspace/apps/`, configures `esp32c6-xiao:usbnsh` and enables `CONFIG_MYHELLO`.

    ./setup.sh
    cd nuttxspace/nuttx
    make -j CROSSDEV=riscv32-esp-elf-

Flash (board connected on `/dev/ttyACM0`; you need to be in the `dialout` group):

    make flash CROSSDEV=riscv32-esp-elf- ESPTOOL_PORT=/dev/ttyACM0 ESPTOOL_BINDIR=./

Simple Boot is used, so no separate bootloader is needed (image is written at 0x0).

## Run

Open the console with `screen`. Close it before flashing again.

    screen /dev/ttyACM0 115200

Press Enter (or reset the board) to get the prompt, then run the app. It blinks
the user LED 10 times by default; pass a count to change that:

    nsh> myhello 5
    Hello from myhello! Blinking LED 5 times

To leave `screen`, press Ctrl-A then `\` (and confirm with `y`), or Ctrl-A then
`k`. Just closing the terminal leaves the session holding the port; list it with
`screen -ls` and remove it with `screen -X -S <session> quit`.
`picocom -b 115200 /dev/ttyACM0` (exit with Ctrl-A Ctrl-X) also works.

## Autostart at boot

`myhello` starts automatically after reset: `setup.sh` enables the `/etc` ROMFS and
patches NuttX's `rcS` startup script (`patches/rcs-autostart-myhello.patch`) to run
`myhello &`. The boot log shows `rcS file is called!`, the LED blinks 10 times, and the
NSH prompt stays available (`ps` lists the running `myhello` task). To disable, drop the
`git apply ...rcs-autostart...` and `-e FS_ROMFS -e ETC_ROMFS` lines from `setup.sh`
and re-run it.

## Build a stock sample (without myhello)

    cd nuttxspace/nuttx
    make distclean
    ./tools/configure.sh esp32c6-xiao:usbnsh
    make -j CROSSDEV=riscv32-esp-elf-

The `usbnsh` config also includes the stock `hello` command.

## Troubleshooting

- Stale dependency paths after switching compilers: remove `myhello/.built`,
  `.depend`, `Make.dep` and `*.o`, then run `make clean`.
- `make distclean` can fail on a half-configured tree; `setup.sh` falls back to
  removing `.config` and `Make.defs`.

## See also

https://wiki.seeedstudio.com/xiao_esp32c6_nuttx/
