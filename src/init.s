.section .init
;;; Init
;;;  Main REPL
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

    ;; Display welcome message
    ld de, glyph_buffer
    ld bc, 0x02
    ld iy, message
    call puts
    ld bc, 0x70

    ;; Start REPL
    call update_mode
read:
    ld de, glyph_buffer
    call display_glyphs

    ld hl, (active_keymap)
    call get_key
    cp 0x00
    jp nz, eval                 ; If valid character, print

    jp read

eval:
    ;; Set flag on shift (2nd) key.
    cp 0xFF
    jp nz, 1f
    ld a, (mode_flag)
    xor 1
    ld (mode_flag), a
    call update_mode
    jp read
1:

    ;; Set flag on Alpha key.
    cp 0xFE
    jp nz, 1f
    ld a, (mode_flag)
    xor 2
    ld (mode_flag), a
    call update_mode
    jp read
1:

    ;; Allow line feed characters
    cp 0x0A
    jp nz, 1f
    call putc
    jp read
1:

    ;; Allow newline characters
    cp 0x0D
    jp nz, 1f
    call putc
    jp read
1:

    ;; Remap delete to form feed (scroll)
    cp 0x08
    jp nz, 1f
    ld a, 0x0C
    call putc
    jp read
1:

    ;; Ignore invalid or null keys
    cp 0x20
    jp c, read

    cp 0x80
    jp nc, read

    ;; Print character
    call putc

    ;; Output over link port and update link status
    call link_putc
    call update_link_stat
    jp read

end:jr $

update_link_stat:
    push af
    push bc
    ld bc, 0x00
    or a
    jp nz, 1f

    ld a, '.'                   ; Success = .
    jp 2f

1:  ld a, '!'                   ; Failed = !

2:  call putc
    pop bc
    pop af
    ret

update_mode:
    push af
    push bc
    push de
    push hl
    ld bc, 0x01

    ld hl, active_keymap
    ld a, (mode_flag)
    cp 1
    jp z, 1f

    cp 2
    jp z, 2f

    cp 3
    jp z, 3f

    ld de, keymap00
    ld a, ' '                   ; No shift = ' '
    jp 4f

1:  ld de, keymap01
    ld a, '2'                   ; Shift = '2'
    jp 4f

2:  ld de, keymap10
    ld a, 'a'                   ; Alpha = 'a'
    jp 4f

3:  ld de, keymap11
    ld a, 'A'                   ; Alpha+Shift = 'A'
    jp 4f

4:  ld (hl), e
    inc hl
    ld (hl), d
    ld de, glyph_buffer
    call putc
    pop hl
    pop de
    pop bc
    pop af
    ret

.section .data
message:
    .db "It works!",0

.section .bss
gfx_buffer:
    .skip 768
gfx_buffer_len equ $ - gfx_buffer
gfx_buffer_end equ $

glyph_buffer:
    .skip 256
glyph_buffer_len equ $ - glyph_buffer
glyph_buffer_end equ $

mode_flag:
    .skip 1

active_keymap:
    .skip 2
