.section .init
init:
    call init_display

    ;; Set screen buffer to pattern.
    ld hl, gfx_buffer
    push hl

    ld (hl), 0xFF
    ld de, gfx_buffer+1
    ld bc, gfx_buffer_len-1
    ldir

    inc bc
    pop iy
    call display_graphic

    ;; Display message
    ld de, glyph_buffer
    ld bc, 0
    ld iy, message
    call puts
    ld bc, 0x10

1:  ld de, glyph_buffer
    call display_glyphs
    call get_key
    cp 0x20
    jp nz, 2f
    ld a, 0x0C
2:  call putc

    call link_putc
    call update_link_stat
    or a
    jp z, 1b

    jp 1b

end:jr $

update_link_stat:
    push af
    push bc
    ld bc, 0x00
    or a
    jp nz, 1f

    ld a, '.'
    jp 2f

1:  ld a, '!'

2:  call putc
    pop bc
    pop af
    ret


.section .data
message:
    .db "  It works!",0

.section .bss
gfx_buffer:
    .skip 768
gfx_buffer_len equ $ - gfx_buffer

glyph_buffer:
    .skip 256
glyph_buffer_len equ $ - glyph_buffer
glyph_buffer_end equ $
