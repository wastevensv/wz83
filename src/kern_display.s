.include "constants.inc.s"

.section .kern
.global init_display
;; Initialize LCD
init_display:
    push af
    ld a, 1 + LCD_CMD_SETDISPLAY
    call lcd_busy_loop
    out (PORT_LCD_CMD), a ; Enable screen

    ld a, 7 + LCD_CMD_POWERSUPPLY_SETLEVEL ; versus +3? TIOS uses +7, and that's the only value that works (the datasheet says go with +3)
    call lcd_busy_loop
    out (PORT_LCD_CMD), a ; Op-amp control (OPA1) set to max (with DB1 set for some reason)

    ld a, 3 + LCD_CMD_POWERSUPPLY_SETENHANCEMENT ; B
    call lcd_busy_loop
    out (PORT_LCD_CMD), a ; Op-amp control (OPA2) set to max

    ld a, 1 + LCD_CMD_AUTOINCDEC_SETX
    call lcd_busy_loop
    out (PORT_LCD_CMD), a       ; X-Increment Mode (vertical)

    pop af
    ret

.global init_text
;; Initialize LCD for text mode
init_text:
    push af
    in a, (PORT_LCD_CMD)        ; Check if already in text mode.
    and LCD_CMD_8BITS
    jp z, 1f
    
    ld a, 0 + LCD_CMD_SETOUTPUTMODE
    call lcd_busy_loop
    out (PORT_LCD_CMD), a       ; 6-bit mode
1:  pop af
    ret

.global init_graphic
;; Initialize LCD for graphical mode
init_graphic:
    push af
    in a, (PORT_LCD_CMD)        ; Check if already in graphic mode.
    and LCD_CMD_8BITS
    jp nz, 1f
    
    ld a, 1 + LCD_CMD_SETOUTPUTMODE
    call lcd_busy_loop
    out (PORT_LCD_CMD), a       ; 8-bit mode
1:  pop af
    ret

.global putg
;; putg
;;  Displays a character 5x6 glyph on the LCD.
;; Inputs:
;;  HL: Glyph to print
;;  D: Starting line (in Pixels)
;;  E: Starting column (in column)
;; Outputs:
;;  None
putg:
    push hl
    push af
    push bc
    push de
        di
        call init_text
    ; Set column
        ld a, e
        add a, LCD_CMD_SETCOLUMN
        call lcd_busy_loop
        out (PORT_LCD_CMD),a

    ; Set row
        ld a, d
        add a, LCD_CMD_SETROW
        call lcd_busy_loop
        out (PORT_LCD_CMD), a

        ld b,5
3: ; Draw character
        ld a, (hl)
        
        call lcd_busy_loop
        out (PORT_LCD_DATA), a
        inc hl
        djnz 3b     ; Advance to next row.

    ; Set row back to initial position.
        ld a, d
        add a, LCD_CMD_SETROW
        call lcd_busy_loop
        out (PORT_LCD_CMD), a
        ei
    pop de
    pop bc
    pop af
    pop hl
    ret

.global putc
;; putc
;;  Displays a character on the LCD
;;  at current location.
;; Inputs:
;;  A: Character to print
;;  D: Starting line (in Pixels)
;;  E: Starting column (in column)
;; Outputs:
;;  None
putc: 
    push hl

    push de
    push af

    sub 0x20        ; Subtract 32 from a.
    ld hl, font
    jp m, 1f

    ld h, 0
    ld l, a

    ld d, 0
    ld e, a

    add hl, hl      ; Double hl (x2)
    add hl, hl      ; Double hl (x4)
    add hl, de      ; a + hl (x5)
    ld de, font
    add hl, de      ; Add base address to offset

1:  pop af
    pop de

    call putg

    pop hl

    ret
    
.global puts
;; puts
;;  Copies a string to the LCD.
;; Inputs:
;;  IY: Text buffer (byte per character)
;;  C: Right Margin (in columns, or 0 for max.)
;;  D: Starting line (in Pixels)
;;  E: Starting column (in columns)
;; Outputs:
;;  D: Ending line (in Pixels)
;;  E: Ending column (in columns)
puts:
    push iy
    push hl
    push bc
    push af
    di
        call init_text
        push af
        push hl
    ; Check for zero right margin.
    ; If right margin is zero, set to max margin.
        ld a, 0
        cp c
        jp nz, 1f
        ld c, 0x10
1: ; Newline
        ld a, e
        add a, LCD_CMD_SETCOLUMN
        call lcd_busy_loop
        out (PORT_LCD_CMD), a
2: ; Next character

        ld a, (iy)      ; Load character code.
        cp 0
        jp z, 3f         ; if 0, end of string.

        call putc
    
        inc iy          ; Advance to next character

        inc e           ; Advance to next column
        ld a, e
        cp c            ; Check if right margin
        jp m, 1b

        ld a, d
        add a, 6
        ld d, a
        ld e, 0
        cp 0x3B
        jp m, 2b        ; Advance to next line
        jp z, 2b
3: ; End loop.
        pop hl
        pop af
    ei
    pop af
    pop bc
    pop hl
    pop iy
    ret


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
