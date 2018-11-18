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

1:  ld de, glyph_buffer
    call display_glyphs
    call get_key
    call putc
    call link_putc
    or a
    jp z, 1b

    ld a, 'F'
    call putc
    jp 1b

end:jr $

.section .data
message:
    .db "It works!",13,10,10,10,10,10,10,"Even with long messages.", 0

.section .bss
gfx_buffer:
    .skip 768
gfx_buffer_len equ $ - gfx_buffer

glyph_buffer:
    .skip 256
glyph_buffer_len equ $ - glyph_buffer
glyph_buffer_end equ $
