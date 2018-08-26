privledgedPage .equ 0x1C

.macro getBankA
    push bc
        in a, (0x0E)
        ld c, a
        rrc c
        in a, (6)
        or c
    pop bc
.endm

.macro getBankB
    push bc
        in a, (0x0F)
        ld c, a
        rrc c
        in a, (7)
        or c
    pop bc
.endm
