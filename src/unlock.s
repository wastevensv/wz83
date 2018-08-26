.include "constants.inc.s"

.section .priv
rst 0 ; Crash before runaway code breaks things

jp _unlockFlash
jp _lockFlash

_unlockFlash:
    ld a,i
    jp pe, 1f
    ld a, i
1:  push af
    di
    ld a, 1
    nop
    nop
    im 1
    di
    out (PORT_FLASHRWCONTROL), a
    pop af
    ret po
    ei
    ret
    
_lockFlash:
    ld a,i
    jp pe, 1f
    ld a, i
1:  push af
    di
    xor a
    nop
    nop
    im 1
    di
    out (PORT_FLASHRWCONTROL), a
    pop af
    ret po
    ei
    ret
