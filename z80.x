/* Default linker script, for normal executables */
/* Copyright (C) 2014-2017 Free Software Foundation, Inc.
   Copying and distribution of this script, with or without modification,
   are permitted in any medium without royalty provided the copyright
   notice and this notice are preserved.  */
/* OUTPUT_FORMAT("binary") */
OUTPUT_ARCH("z80")

MEMORY
{
    rom  (rx)  : ORIGIN = 0x0000, LENGTH = 512k
}
SECTIONS
{
    .kern 0x0 : AT(0x0)  {
        *(.boot)
        *(.kern)
    } > rom
    .text 0x4000 : AT(0x4000) {
        out/init.o(.text)
        *(.text)
        *(.data)
    } > rom
    .priv 0x4000 : AT(0x70000) {
        *(.priv)
    } > rom
    .pad : AT(LENGTH(rom) -1) {
	 BYTE(0x42)
    } > rom
}
