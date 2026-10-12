# Apache NuttX primer and examples


## Install requirements

    sudo apt install -y bison flex gperf libncurses5-dev libgmp-dev libmpc-dev libmpfr-dev binutils-dev
    sudo apt install kconfig-frontends-nox

    sudo apt install esptool gcc-riscv64-unknown-elf
    mkdir nuttxspace
    cd nuttxspace
    git clone --depth=1 https://github.com/apache/nuttx.git nuttx
    git clone --depth=1 https://github.com/apache/nuttx-apps apps

## Build a sample

    cd nuttx
    make distclean
    ./tools/configure.sh esp32c6-xiao:usbnsh
    make V=1

## Build the custom myhello app

The app lives in `myhello/` (outside the NuttX tree). `setup.sh` symlinks it
into `nuttxspace/apps/`, configures `esp32c6-xiao:usbnsh` and enables `CONFIG_MYHELLO`.

    ./setup.sh
    cd nuttxspace/nuttx
    make -j
    esptool.py --chip esp32c6 -p /dev/ttyACM0 -b 460800 write_flash 0x0 nuttx.bin

If flashing at 0x0 fails, see the Seeed wiki below for the bootloader and offsets.
Then in the NSH prompt run `myhello`.

## See also

https://wiki.seeedstudio.com/xiao_esp32c6_nuttx/

