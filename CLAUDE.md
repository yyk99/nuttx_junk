# CLAUDE.md

Minimal Apache NuttX project for the Seeed XIAO ESP32C6: a custom `myhello` app
that blinks the user LED and starts at boot. See README.md for full install, build,
flash and run steps.

## Layout

- `myhello/` - the custom app (Kconfig, Make.defs, Makefile, CMakeLists.txt, main).
  It is symlinked into the NuttX apps tree as `nuttxspace/apps/external`.
- `patches/` - patches applied to the NuttX tree by the setup scripts:
  - `xiao-led-gpio15.patch` - routes the board GPIO output (`/dev/gpio0`) to the user LED (GPIO15)
  - `rcs-autostart-myhello.patch` - runs `myhello &` from `etc/init.d/rcS`
  - `cmake-esp-toolchain.patch` - teaches NuttX CMake the `riscv32-esp-elf` prefix
- `setup.sh` - Make flow: link app, `distclean`, `configure.sh esp32c6-xiao:usbnsh`, apply patches, enable options
- `setup_cmake.sh` - CMake/Ninja flow; output in `nuttxspace/build/`
- `nuttxspace/` - git-ignored clones of `nuttx` and `apps`; never commit or reformat anything there.
  Changes to NuttX must go through a patch in `patches/`.
- `.venv/` - git-ignored Python venv (esptool >= 4.8, kconfiglib)

## Build and flash (Make)

    source .venv/bin/activate
    export PATH=<riscv32-esp-elf toolchain>/bin:$PATH
    ./setup.sh
    cd nuttxspace/nuttx
    make -j CROSSDEV=riscv32-esp-elf-
    make flash CROSSDEV=riscv32-esp-elf- ESPTOOL_PORT=/dev/ttyACM0 ESPTOOL_BINDIR=./

Console: `screen /dev/ttyACM0 115200`. Close it before flashing (the port must be free).

## Gotchas

- The apt `gcc-riscv64-unknown-elf` has no libc headers; use Espressif's `riscv32-esp-elf`.
- NuttX needs `esptool.py` >= 4.8; apt has 4.7. Use the venv (`.venv/bin/esptool.py`).
- Building the `/etc` ROMFS needs `genromfs` (apt).
- CMake refuses an in-tree `.config`; `setup_cmake.sh` runs `make distclean`. Re-run `./setup.sh` to go back to Make.
- Stale `.depend`, `Make.dep`, `.built` or `*.o` in `myhello/` after switching compilers cause
  "No rule to make target ...stdarg.h" errors; delete them and `make clean`.
- The board may disappear from `/dev/ttyACM0` after a crash or reflash; replug it (hold BOOT for download mode).
- Build and hardware checks can be done here, but only the user can see the LED; ask them to confirm blinking.

## Conventions

- C style is K&R, enforced by `.clang-format` (4 spaces, attached braces). Do not run clang-format over `nuttxspace/`.
- Git commit messages: ASCII only, no emoji, hyphens for lists.
- Work on a feature branch (`devel/yyk99/<topic>`), never on `master`; merge PRs with squash.
- A PR description starts with `Closes #N` / `Fixes #N` when a related issue exists. Do not
  create an issue automatically; PRs may have no issue. Carry the reference into the squash message.
- Do not commit, push, merge, or flash the board unless asked.
