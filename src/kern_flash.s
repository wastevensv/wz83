.include "constants.inc.s"
.include "flash.inc.s"

.section .ktext

;;; Prevent runaway code from unlocking flash.
    rst 0; Just in case.

.global unlockFlash
;;; unlockFlash
;;;  Unlocks Flash and unlocks protected ports.
;;; Notes:
;;;  **Do not use this unless you know what you're doing.**
;;;
;;;  Please call [[lockFlash]] when you finish what you're doing and don't spend too
;;;  much time with Flash unlocked. Disable interrupts while Flash is unlocked.
unlockFlash:
    push af
    push bc
        in a, (PORT_BANKA)      ; Read current page state
        push af
            ld a, privledgedPage
            out (PORT_BANKA), a     ; Map privledged page to RAM
            ld b, 0x01
            ld c, 0x14
            call 0x4001             ; Call _unlockFlash from privledged page.
                                    ; (see unlock.s)
        pop af
        out (PORT_BANKA), a     ; Restore previous page state
    pop bc
    pop af
    ret

.global lockFlash
;;; lockFlash
;;;  Locks Flash and locks protected ports.
lockFlash:
    push af
    push bc
        in a, (PORT_BANKA)      ; Read current page state
        push af
            ld a, privledgedPage
            out (PORT_BANKA), a     ; Map privledged page to RAM
            ld b, 0x00
            ld c, 0x14
            call 0x4004             ; Call _lockFlash from privledged page.
                                    ; (see unlock.s)

        pop af
        out (PORT_BANKA), a     ; Restore previous page state
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
