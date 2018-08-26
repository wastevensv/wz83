.include "constants.inc.s"

.section .boot
startup:
    di

    ; Re-map memory
    ld a, 3 << MEM_TIMER_SPEED
    out (PORT_MEM_TIMER), a

    ; Set memory mapping
    ; Bank 0: Flash Page 00
    ; Bank 1: Flash Page *
    ; Bank 2: RAM Page 01
    ; Bank 3: RAM Page 00
    ld a, 1 | BANKB_ISRAM_CPU6
    out (PORT_BANKB), a

    ld hl, 0x8000
    ld (hl), 0
    ld de, 0x8001
    ld bc, 0x7FFF
    ldir

    call unlockFlash
    call unprotectRAM
    call unprotectFlash
    call lockFlash

    ld a, INT_ON | INT_TIMER1 | INT_LINK
    out (PORT_INT_MASK), a

    ld a, 1 ; Init program in page 2
    out (PORT_BANKA), a

    jp 0x4000
    rst 0 ; Prevent runaway code from unlocking flash
