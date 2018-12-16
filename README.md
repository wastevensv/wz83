# wz83

An alternative TI-83+ firmware.

## Status
[x] Calculator boots
[x] Power off/on interrupts
[x] Display Output
[x] Keypad Input
[x] Link Port Output
[ ] Link Port Input
[ ] RPN REPL
[ ] Forth?

## Build Dependencies
* Z80 binutils
  * [binutils-z80](https://packages.debian.org/stretch/binutils-z80) deb package (older, but easier in some cases)
  * [source](https://ftp.gnu.org/gnu/binutils/) (recommended, use newest version)
    * Build with:
      * `./configure --target=z80-unknown-coff`
      * `make`
      * `make -k check` (required step for binutils)
      * `sudo make install`
* mktiupgrade (for creating update packages)
  * [source](https://github.com/KnightOS/mktiupgrade)
  * [AUR package](https://aur.archlinux.org/packages/mktiupgrade/)
* z80e Emulator (for testing or debugging)
  * [source](https://github.com/KnightOS/z80e) (recommended)
  * [AUR package](https://aur.archlinux.org/packages/z80e/) (missing some bugfixes)
* TiLP (for loading onto a calculator)
  * [homepage](http://lpg.ticalc.org/prj_tilp/)
  * [tilp2](https://packages.debian.org/stretch/tilp2) deb package
  * [tilp](https://aur.archlinux.org/packages/tilp/) AUR package

## How to Build
* For testing: `make run`
* For debugging: `make debug`
* For building a firmware update: `make signed`
  * NOTE: The keys for signing are not stored here. They can be [obtained](https://brandonw.net/calculators/keys/) [elsewhere](https://github.com/KnightOS/kernel/blob/master/keys/04.key).
  * Place the 04.key file in the root directory.

## How to Load a Firmware Update
1. Connect the calculator to the computer using a link cable.
2. Press and hold the `DEL` key on the calculator.
3. While holding the `DEL` key, remove and replace a battery.
4. A bootloader screen will appear.
5. Use TiLP to transfer the frimware update to the calculator.
