.section .text
start:
    call init_display
    
    ;; Set screen buffer to pattern.
    ld hl, 0xC000
    push hl

    ld (hl), 0xFF
    ld de, 0xC001
    ld bc, 767
    ldir

    pop iy
    call display_graphic

    ld c, 0
    ld e, 1
    ld d, 2
    ld iy, message
    call puts
    ld iy, messageB
    call puts
    jr $

.section .data
message:
    .db "Hello, userspace!", 0
messageB:
    .db " It works!", 0
