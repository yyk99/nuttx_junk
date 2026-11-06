# Apache NuttX primer and examples

Minimal NuttX setup with a custom `myhello` app that blinks the user LED. One
setup script configures NuttX for any of the supported boards.

## Boards

| Board | Directory | Toolchain | Autostart |
|-------|-----------|-----------|-----------|
| Seeed XIAO ESP32C6 | [boards/xiao-esp32c6](boards/xiao-esp32c6/README.md) | `riscv32-esp-elf` | yes |
| ST Nucleo-F767ZI | [boards/nucleo-f767zi](boards/nucleo-f767zi/README.md) | `arm-none-eabi` | no |

Each board directory has its own README with the toolchain, build, flash and
console steps.

## Common requirements

Packages (Ubuntu/Debian):

    sudo apt install -y bison flex gperf libncurses5-dev libgmp-dev libmpc-dev libmpfr-dev binutils-dev
    sudo apt install -y kconfig-frontends-nox genromfs screen

CMake mode (any board) also needs `cmake`, `ninja-build` and `kconfiglib`
(`pip install kconfiglib`, in a venv or system-wide).

Get the sources (from the root of this repo; `nuttxspace/` is git-ignored):

    mkdir nuttxspace
    git clone --depth=1 https://github.com/apache/nuttx.git nuttxspace/nuttx
    git clone --depth=1 https://github.com/apache/nuttx-apps nuttxspace/apps

## Configure and build

    export PATH=<toolchain>/bin:$PATH    # toolchain of the board (see its README)
    ./setup.sh <board> [make|cmake]      # default: make
    cd nuttxspace/nuttx
    make -j CROSSDEV=<toolchain prefix>  # Make flow; setup.sh prints the exact command

`setup.sh` exits early if the board's compiler is not on `PATH`. It symlinks `myhello/` into `nuttxspace/apps/external`, resets the NuttX
tree (`git checkout .`, so patches from a previously configured board go away),
runs `make distclean`, applies the board's patches, configures the board and enables
the options listed in its `board.conf`. In `cmake` mode it also builds with Ninja;
the image is `nuttxspace/build/nuttx.bin`. Do not keep hand edits in
`nuttxspace/nuttx`: changes to NuttX go through a patch.

All boards share `nuttxspace/`, so there is one build at a time:

| Mode | Image |
|------|-------|
| `make` | `nuttxspace/nuttx/nuttx.bin` (in-tree build) |
| `cmake` | `nuttxspace/build/nuttx.bin` |

Running `setup.sh` for another board discards the previous board's patches and build
(`git checkout .`, `make distclean`, and `rm -rf nuttxspace/build` in CMake mode), so
rebuild after switching back. Flash before you switch.

The `myhello` app drives the user LED through `CONFIG_MYHELLO_GPIO_DEVPATH` (default
`/dev/gpio0`); `CONFIG_MYHELLO_LED_ACTIVE_LOW` selects the LED polarity. Both are set per
board in `board.conf`.

## Adding a board

1. Find its NuttX config (`ls nuttxspace/nuttx/boards/*/*/<board>/configs`).
2. Create `boards/<name>/board.conf` with `NUTTX_CONFIG`, `CROSSDEV` and
   `KCONFIG_TWEAKS` (see the existing ones).
3. If the user LED is not `/dev/gpio0` (set `MYHELLO_GPIO_DEVPATH`), or the board needs other NuttX changes, add
   `boards/<name>/patches/*.patch` (made with `git diff` inside `nuttxspace/nuttx`).
   Patches in `patches/cmake/` are applied only in `cmake` mode.
4. Add `boards/<name>/README.md` and a row in the table above.

## Troubleshooting

- Stale dependency paths after switching compilers: remove `myhello/.built`,
  `.depend`, `Make.dep` and `*.o`, then run `make clean`.
- `make distclean` can fail on a half-configured tree; `setup.sh` falls back to
  removing `.config` and `Make.defs`.
