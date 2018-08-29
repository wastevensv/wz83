.section .init
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

    ;; Display messages
    ld c, 0
    ld e, 1
    ld d, 2
    ld iy, message
    call puts
    ld iy, messageB
    call puts
1:
    call get_key
    cp 0x0A
    jp z, end
    call putc
    jp 1b
end:jr $

.section .data
message:
    .db "Hello, userspace!", 0
messageB:
    .db " It works!", 0
