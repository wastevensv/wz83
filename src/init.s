.section .init
init:
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

1:  call newline
    ld a, '>'
    call putc

2:  call get_key
    cp 0x0A
    jp z, 1b
    call putc
    cp 0x0D
    call z, poweroff
    jp 2b

end:jr $

.section .data
message:
    .db "It works!", 0
