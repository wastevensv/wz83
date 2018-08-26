.include "constants.inc.s"
.include "flash.inc.s"

.section .kern

    rst 0; Just in case.

;; unlockFlash [Flash]
;;  Unlocks Flash and unlocks protected ports.
;; Notes:
;;  **Do not use this unless you know what you're doing.**
;;  
;;  Please call [[lockFlash]] when you finish what you're doing and don't spend too
;;  much time with Flash unlocked. Disable interrupts while Flash is unlocked.
.global unlockFlash
unlockFlash:
    push af
    push bc
        in a, (6)
        push af
            ld a, privledgedPage 
            out (6), a
            ld b, 0x01
            ld c, 0x14
            call 0x4001
        pop af
        out (6), a
    pop bc
    pop af
    ret

;; lockFlash [Flash]
;;  Locks Flash and locks protected ports.
.global lockFlash
lockFlash:
    push af
    push bc
        in a, (6)
        push af
            ld a, privledgedPage 
            out (6), a
            ld b, 0x00
            ld c, 0x14
            call 0x4004
        pop af
        out (6), a
    pop bc
    pop af
    ret


.global unprotectRAM
unprotectRAM:
   xor a
   out (PORT_RAM_PAGING), a
   out (PORT_FLASHEXCLUSION), a

   ld a, 0b000000001
   out (PORT_RAM_PAGING), a
   xor a
   out (PORT_FLASHEXCLUSION), a
   ret

.global unprotectFlash
unprotectFlash:
   ld a, 0b000000010
   out (PORT_RAM_PAGING), a
   xor a
   out (PORT_FLASHEXCLUSION), a

   ld a, 0b000000111
   out (PORT_RAM_PAGING), a
   xor a
   out (PORT_FLASHEXCLUSION), a
   ret
