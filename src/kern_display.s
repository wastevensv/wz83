.include "constants.inc.s"

.section .kern
.global init_display
;; Initialize LCD
init_display:
    ld a, 1 + LCD_CMD_SETDISPLAY
    call lcd_busy_loop
    out (PORT_LCD_CMD), a ; Enable screen

    ld a, 7 + LCD_CMD_POWERSUPPLY_SETLEVEL ; versus +3? TIOS uses +7, and that's the only value that works (the datasheet says go with +3)
    call lcd_busy_loop
    out (PORT_LCD_CMD), a ; Op-amp control (OPA1) set to max (with DB1 set for some reason)

    ld a, 3 + LCD_CMD_POWERSUPPLY_SETENHANCEMENT ; B
    call lcd_busy_loop
    out (PORT_LCD_CMD), a ; Op-amp control (OPA2) set to max

    ret

.global init_text
;; Initialize LCD for text mode
init_text:
    ld a, 1 + LCD_CMD_AUTOINCDEC_SETX
    call lcd_busy_loop
    out (PORT_LCD_CMD), a ; X-Increment Mode (vertical)

    ld a, 0 + LCD_CMD_SETOUTPUTMODE
    call lcd_busy_loop
    out (PORT_LCD_CMD), a ; 6-bit mode

    ret

.global init_graphic
;; Initialize LCD for graphical mode
init_graphic:
    ld a, 1 + LCD_CMD_AUTOINCDEC_SETX
    call lcd_busy_loop
    out (PORT_LCD_CMD), a ; X-Increment Mode (vertical)

    ld a, 1 + LCD_CMD_SETOUTPUTMODE
    call lcd_busy_loop
    out (PORT_LCD_CMD), a ; 8-bit mode

    ret

.global display_text
;; display_text
;;  Copies a string to the LCD.
;; Inputs:
;;  IY: Text buffer (byte per character)
;;  D: Starting line (in Pixels)
;;  E: Starting column (in columns)
;; Outputs:
;;  D: Ending line (in Pixels)
;;  E: Ending column (in columns)
display_text:
        push iy
        push hl
        push bc
        push af
            di
            call init_text
            ld a, i
            push af
            push hl

                ld a, d
                add a, LCD_CMD_SETROW
                ld d, a

1: ; Newline
                call lcd_busy_loop
                out (PORT_LCD_CMD), a
2: ; Next character
;;; TODO: Move into seperate putchar function
                ld a, e
                add a, LCD_CMD_SETCOLUMN
                call lcd_busy_loop
                out (PORT_LCD_CMD),a

                push bc
                push de

                ld d, 0
                ld e, (iy)      ; Load character code.
                inc e
                dec e 
                jp z, 5f         ; if 0, end of string.

                ld hl, 0
                add hl, de
                add hl, hl      ; Double hl (2B adresses in LUT)
                ld de, font_lut
                add hl, de      ; Add base address to offset
                ld b, (hl)
                inc hl
                ld h, (hl)      ; Load address of character
                ld l, b

                pop de
                pop bc

                push hl
                push af
                push bc
                    ld b,5
3: ; Draw character
                    ld a, (hl)
                    
                    call lcd_busy_loop
                    out (PORT_LCD_DATA), a
                    inc hl
                    djnz 3b     ; Advance to next row.

                    ld a, d
                    call lcd_busy_loop
                    out (PORT_LCD_CMD), a
                pop bc
                pop af
                pop hl

                inc iy          ; Advance to next character

                inc e           ; Advance to next column
                cp 0x0F + LCD_CMD_SETCOLUMN ; Check if last column
                jp m, 2b

                ld a, d
                add a, 6
                ld d, a
                ld e, 0
                cp 0x3B + LCD_CMD_SETROW
                jp m, 1b        ; Advance to next line
                jp z, 1b
4: ; End loop.
            ld a, d
            sub LCD_CMD_SETROW
            ld d, a
            pop hl
            pop af
        ei
    pop af
    pop bc
    pop hl
    pop iy
    ret

5: ; Handle NUL terminator.
    pop de
    pop af
    jp 4b


.global display_graphic
;; display_graphic
;;  Copies a screen buffer to the LCD.
;; Inputs:
;;  IY: Screen buffer (bit per pixel)
display_graphic:
        push hl
        push bc
        push af
        push de
            di
            call init_graphic
            ld a, i
            push af
                push iy
                pop hl

                ld a, LCD_CMD_SETROW
                call lcd_busy_loop
                out (PORT_LCD_CMD), a

                ld de, 12
                ld a, LCD_CMD_SETCOLUMN
1: ; Set column
                call lcd_busy_loop
                out (PORT_LCD_CMD),a

                push af
                    ld b,64
2: ; Draw row
                    ld a, (hl)
                    call lcd_busy_loop
                    out (PORT_LCD_DATA), a
                    add hl, de
                    djnz 2b
                pop af
                dec h
                dec h
                dec h
                inc hl
                inc a
                cp 0x0C + LCD_CMD_SETCOLUMN
                jp nz, 1b
            pop af
        ei
    pop de
    pop af
    pop bc
    pop hl
    ret

.global lcd_busy_loop
;; lcd_busy_loop
;;  Waits for LCD to become ready.
;; Inputs:
;;  None
lcd_busy_loop:
    push bc
    ld c, PORT_LCD_CMD
loop$:
    in b, (c)    ;bit 7 set if LCD is busy
    jp m, loop$  ;repeat if bit 7 (sign bit) set.
    pop bc
    ret
