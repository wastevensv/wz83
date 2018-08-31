.include "constants.inc.s"

.section .boot

boot: 
    in a, (PORT_FLASHRAMSIZE)
    set BIT_FLASHRAMSIZE_FLASHCHIP, a
    out (PORT_FLASHRAMSIZE), a
    jp startup

