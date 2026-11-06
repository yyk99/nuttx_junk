# CLAUDE.md

Minimal Apache NuttX project for several boards (Seeed XIAO ESP32C6, ST Nucleo-F767ZI):
a custom `myhello` app that blinks the user LED. See README.md for full install, build,
flash and run steps.

## Layout

- `myhello/` - the custom app (Kconfig, Make.defs, Makefile, CMakeLists.txt, main).
  It is symlinked into the NuttX apps tree as `nuttxspace/apps/external`.
  Board differences are Kconfig options (e.g. `MYHELLO_LED_ACTIVE_LOW`), never `#ifdef` on boards.
- `boards/<name>/` - one directory per supported board (`xiao-esp32c6`, `nucleo-f767zi`):
  - `board.conf` - `NUTTX_CONFIG`, `CROSSDEV`, `KCONFIG_TWEAKS`, sourced by `setup.sh`
  - `patches/*.patch` - applied to the NuttX tree; `patches/cmake/*.patch` only in cmake mode
  - `README.md` - toolchain, build, flash and console steps for that board
- `setup.sh <board> [make|cmake]` - links the app, runs `git checkout .` and `distclean` in the
  NuttX tree, applies the board's patches, configures it and enables the options.
  CMake output goes to `nuttxspace/build/`.
- `nuttxspace/` - git-ignored clones of `nuttx` and `apps`; never commit or reformat anything there.
  Changes to NuttX must go through a patch in `boards/<name>/patches/`
  (`setup.sh` discards any other edit).
- `.venv/` - git-ignored Python venv (esptool >= 4.8, kconfiglib)

## Build and flash

    source .venv/bin/activate    # ESP boards only (esptool)
    export PATH=<toolchain>/bin:$PATH
    ./setup.sh <board>
    cd nuttxspace/nuttx
    make -j CROSSDEV=<prefix from board.conf>

Flash and console steps differ per board; see `boards/<name>/README.md`.

## Gotchas

- The apt `gcc-riscv64-unknown-elf` has no libc headers; use Espressif's `riscv32-esp-elf`.
- NuttX needs `esptool.py` >= 4.8; apt has 4.7. Use the venv (`.venv/bin/esptool.py`).
- Building the `/etc` ROMFS needs `genromfs` (apt).
- CMake refuses an in-tree `.config`; `setup.sh ... cmake` runs `make distclean`. Re-run it without `cmake` to go back to Make.
- Stale `.depend`, `Make.dep`, `.built` or `*.o` in `myhello/` after switching compilers cause
  "No rule to make target ...stdarg.h" errors; delete them and `make clean`.
- The board may disappear from `/dev/ttyACM0` after a crash or reflash; replug it (XIAO: hold BOOT for download mode).
- The Nucleo-F767ZI here has SEGGER J-Link firmware on its debugger: OpenOCD cannot flash it; use `JLinkExe` (bundled with STM32CubeIDE in `/opt/st/`).
- Build and hardware checks can be done here, but only the user can see the LED; ask them to confirm blinking.

## Conventions

- C style is K&R, enforced by `.clang-format` (4 spaces, attached braces). Do not run clang-format over `nuttxspace/`.
- Git commit messages: ASCII only, no emoji, hyphens for lists.
- Work on a feature branch (`devel/yyk99/<topic>`), never on `master`; merge PRs with squash.
- A PR description starts with `Closes #N` / `Fixes #N` when a related issue exists. Do not
  create an issue automatically; PRs may have no issue. Carry the reference into the squash message.
- Do not commit, push, merge, or flash the board unless asked.
