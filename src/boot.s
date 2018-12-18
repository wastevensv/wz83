.include "constants.inc.s"

.section .boot                  ; Loaded into page 0x1E

boot:
;;; Boot routine. Jump to startup.
    in a, (PORT_FLASHRAMSIZE)
    set BIT_FLASHRAMSIZE_FLASHCHIP, a
    out (PORT_FLASHRAMSIZE), a
    jp startup
