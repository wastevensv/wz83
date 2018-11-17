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

    ld de, glyph_buffer
    call display_glyphs

end:jr $

.section .data
message:
    .db "It works!",10,13,"Even with long messages.", 0

.section .bss
gfx_buffer:
    .skip 768
gfx_buffer_len equ $ - gfx_buffer

glyph_buffer:
    .skip 256
glyph_buffer_len equ $ - glyph_buffer
glyph_buffer_end equ $
