# Apache NuttX primer and examples

Minimal NuttX setup for the Seeed XIAO ESP32C6, with a custom `myhello` app.

## Install requirements

Packages (Ubuntu/Debian):

    sudo apt install -y bison flex gperf libncurses5-dev libgmp-dev libmpc-dev libmpfr-dev binutils-dev
    sudo apt install -y kconfig-frontends-nox picocom python3-venv

esptool: NuttX needs `esptool.py` >= 4.8, but apt only has 4.7 (installed as
`esptool`). Install a current one in a Python venv at the repo root (it provides
`esptool.py`) and activate it in every shell you build from:

    python3 -m venv .venv
    .venv/bin/pip install esptool
    source .venv/bin/activate

Toolchain: use Espressif's `riscv32-esp-elf` GCC (the apt `gcc-riscv64-unknown-elf`
has no libc headers and fails with `sys/lock.h: No such file or directory`).
Download it from https://github.com/espressif/crosstool-NG/releases and put its
`bin/` directory on `PATH`. If you have the Arduino ESP32 core installed, its copy works:

    export PATH=$HOME/.arduino15/packages/esp32/tools/esp-rv32/2601/bin:$PATH

Check: `riscv32-esp-elf-gcc --version` and `esptool.py version`.

Note: the standalone toolchain download is untested here; the Arduino toolchain was
what was actually used. The venv esptool install was verified (5.5.0).

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

Open the console (exit with Ctrl-A Ctrl-X). Close it before flashing again.

    picocom -b 115200 /dev/ttyACM0

Press Enter (or reset the board) to get the prompt, then:

    nsh> myhello
    Hello from myhello!

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
