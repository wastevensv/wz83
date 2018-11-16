.section .init
init:
    call init_display

    ;; Set screen buffer to pattern.
    ld hl, gfx_buffer
    push hl

    ld (hl), 0xFF
    ld de, gfx_buffer+1
    ld bc, gfx_buffer_len
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

.section .bss
gfx_buffer:
    .skip 767
gfx_buffer_len equ $ - gfx_buffer

txt_buffer:
    .skip 400
txt_buffer_len equ $ - txt_buffer
