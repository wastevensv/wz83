.section .text
start:
    call init_display
    
    ;; Set screen buffer to pattern.
    ld hl, 0xC000
    push hl

    ld (hl), 0x55
    ld de, 0xC001
    ld bc, 767
    ldir

    pop iy
    call display_graphic

    ld iy, font_map
    call display_text
    jr $

.section .data
message:
    .db "Hello, userspace!", 0
