.section .text
start:
    ld hl, message

    ;; Set screen buffer to pattern.
    ld hl, 0xC000
    push hl
    ld (hl), 0xCC
    ld de, 0xC001
    ld bc, 767
    ldir

    pop iy
    call display_copy
    jr $

.section .data
message:
    .db "Hello, userspace!", 0
