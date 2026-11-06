# ST Nucleo-F767ZI

NuttX config `nucleo-f767zi:nsh`. LD1 (PB0, green, active high) is `/dev/gpio4`: the board registers its 4 GPIO
inputs first, then the outputs (LD1-LD3 are `gpio4`-`gpio6`). `board.conf` sets
`CONFIG_MYHELLO_GPIO_DEVPATH` accordingly and turns `CONFIG_MYHELLO_LED_ACTIVE_LOW` off. It also disables
`CONFIG_ARCH_LEDS`; otherwise the kernel uses LD1-LD3 as status LEDs and overrides `myhello`. No NuttX patches are needed.

## kestrel

```
cd ~/src/nuttx_junk
./setup.sh nucleo-f767zi
cd nuttxspace/nuttx
make -j $(nproc) CROSSDEV=arm-none-eabi-

printf 'r\nh\nloadbin nuttx.bin 0x08000000\nr\ng\nexit\n' > /tmp/flash.jlink
JLINK=$(ls /opt/st/stm32cubeide_*/plugins/*externaltools.jlink.linux64_*/tools/bin/JLinkExe)
$JLINK -device STM32F767ZI -if SWD -speed 4000 -autoconnect 1 -NoGui 1 -ExitOnError 1 -CommandFile /tmp/flash.jlink
```
Then the console (close it before flashing again). Press Enter for the prompt:
```
screen /dev/ttyACM0 115200
nsh> myhello 5
```

## Toolchain

`arm-none-eabi-gcc` (apt `gcc-arm-none-eabi`). Tested with 13.2.1.

## Build

    ./setup.sh nucleo-f767zi
    cd nuttxspace/nuttx
    make -j CROSSDEV=arm-none-eabi-

The image is `nuttxspace/nuttx/nuttx.bin` (flash address 0x08000000). Configuring another
board with `setup.sh` removes it, so flash before you switch.

## Flash

With the stock ST-LINK firmware:

    openocd -f interface/stlink.cfg -f target/stm32f7x.cfg \
        -c "program nuttx.bin 0x08000000 verify reset exit"

If the on-board debugger runs SEGGER J-Link firmware (`lsusb` shows `1366:0105`;
this is the case for the board used here), OpenOCD cannot use it. Use `JLinkExe`
(on PATH, or the copy bundled with STM32CubeIDE under `/opt/st/`) with a command file:

    r
    h
    loadbin nuttx.bin 0x08000000
    r
    g
    exit

    JLinkExe -device STM32F767ZI -if SWD -speed 4000 -autoconnect 1 -NoGui 1 \
        -ExitOnError 1 -CommandFile flash.jlink

## Run

The console is the debugger's virtual COM port (`/dev/ttyACM0`, 115200). Close it
before flashing.

    screen /dev/ttyACM0 115200
    nsh> myhello 5

`myhello` does not start at boot on this board: the `nsh` config has no
`/etc/init.d/rcS` or ROMFS mount.
