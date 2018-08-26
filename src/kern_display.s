.include "constants.inc.s"

.section .kern

.global lcd_busy_loop
lcd_busy_loop:
    push bc
    ld c, PORT_LCD_CMD
loop$:
    in b, (c)    ;bit 7 set if LCD is busy
    jp m, loop$  ;repeat if bit 7 (sign bit) set.
    pop bc
    ret

.global display_copy
;; display_copy
;;  Copies the screen buffer to the LCD.
;; Inputs:
;;  IY: Screen buffer
display_copy:
        push hl
        push bc
        push af
        push de
            di
            ld a, i
            push af
                push iy
                pop hl

                ld a, LCD_CMD_SETROW
                call lcd_busy_loop
                out (PORT_LCD_CMD), a

                ld de, 12
                ld a, LCD_CMD_SETCOLUMN
col$: ; Set column
                call lcd_busy_loop
                out (PORT_LCD_CMD),a

                push af
                    ld b,64
row$: ; Draw row
                    ld a, (hl)
                    call lcd_busy_loop
                    out (PORT_LCD_DATA), a
                    add hl, de
                    djnz row$
                pop af
                dec h
                dec h
                dec h
                inc hl
                inc a
                cp 0x0C + LCD_CMD_SETCOLUMN
                jp nz, col$
            pop af
        jp po, ret$
        ei
ret$:
    pop de
    pop af
    pop bc
    pop hl
    ret
