.include "constants.inc.s"

.section .ktext
.global init_display
;;; Initialize LCD
init_display:
    push af
    ld a, 1 + LCD_CMD_SETDISPLAY
    call lcd_busy_loop
    out (PORT_LCD_CMD), a                   ; Enable screen

    ld a, 7 + LCD_CMD_POWERSUPPLY_SETLEVEL  ; versus +3? TIOS uses +7,
                                            ; and that's the only value
                                            ; that works (the datasheet
                                            ; says go with +3)
    call lcd_busy_loop
    out (PORT_LCD_CMD), a                   ; Op-amp control (OPA1) set
                                            ; to max (with DB1 set for
                                            ; some reason)

    ld a, 3 + LCD_CMD_POWERSUPPLY_SETENHANCEMENT ; B
    call lcd_busy_loop
    out (PORT_LCD_CMD), a                   ; Op-amp control (OPA2) set
                                            ; to max

    ld a, 1 + LCD_CMD_AUTOINCDEC_SETX
    call lcd_busy_loop
    out (PORT_LCD_CMD), a                   ; X-Increment Mode (vertical)

    ld a, 0x3F + LCD_CMD_SETCONTRAST
    call lcd_busy_loop
    out (PORT_LCD_CMD), a                   ; Contrast

    pop af
    ret

.global init_text
;;; Initialize LCD for text mode
init_text:
    push af
    ;; Check if already in text mode.
    in a, (PORT_LCD_CMD)
    and LCD_CMD_8BITS
    jp z, 1f

    ;; Set to 6-bit mode
    ld a, 0 + LCD_CMD_SETOUTPUTMODE
    call lcd_busy_loop
    out (PORT_LCD_CMD), a
1:  pop af
    ret

.global init_graphic
;;; Initialize LCD for graphical mode
init_graphic:
    push af
    ;; Check if already in graphic mode.
    in a, (PORT_LCD_CMD)
    and LCD_CMD_8BITS
    jp nz, 1f

    ;; Set to 8-bit mode
    ld a, 1 + LCD_CMD_SETOUTPUTMODE
    call lcd_busy_loop
    out (PORT_LCD_CMD), a
1:  pop af
    ret

.global putc
;;; putc
;;;  Translate a character to a glyph and insert
;;;  it into the buffer at current location.
;;; Inputs:
;;;  A: Character to print
;;;  DE: Base address of glyph buffer
;;;  BC: Offset into glyph buffer (in characters)
;;; Outputs:
;;;  BC: New offset into glyph buffer
putc:
    push af
    push hl

    ;; if Backspace, clear last glyph.
    cp 0x08
    call z, backspace
    jp z, 2f

    ;; if LF, advance to next line.
    cp 0x0A
    call z, newline
    jp z, 2f

    ;; if CR, return to start of line.
    cp 0x0D
    call z, carriage
    jp z, 2f

    ;; if FF, move screen up one line.
    cp 0x0C
    call z, scroll
    jp z, 2f

    ;; Calculate offset
    push bc
    ld  h, d        ; hl = position
    ld  l, e
    rl  c           ; 1 character = 2 bytes
    add hl, bc      ; Add 2*pos to offset
    pop bc

    push de
    push hl
    ;; Check for invalid codes.
    sub 0x20        ; Subtract 32 from a.
    ld hl, font
    jp c, 1f        ; If result is negative, print blank.

    ;; Calculate glyph address
    ld h, 0
    ld l, a

    ld d, 0
    ld e, a

    add hl, hl      ; Double hl (x2)
    add hl, hl      ; Double hl (x4)
    add hl, de      ; a + hl (x5)
    ld de, font
    add hl, de      ; Add base address to offset

    ex de, hl       ; Glyph pointer now in de.

1:  pop hl

    ;; Store glyph pointer in buffer.
    ld (hl), d
    inc hl
    ld (hl), e

    pop de

    ;; Next character
    inc bc
2:
    ;; Check for end of buffer.
    ld a, c
    cp 0x80         ; Is buffer offset overflowed?
    jp c, 3f        ; If not, return.

    ;; Scroll to next line if at end of buffer.
    call scroll     ; Else, scroll
    ld bc, 0x70     ; Reset to start of last line.

3:
    pop hl
    pop af
    ret

;;; backspace
;;;  BC: Offset into glyph buffer (in characters)
backspace:
    dec bc
    ret

;;; Newline
;;;  DE: Base address of glyph buffer
;;;  BC: Offset into glyph buffer (in characters)
newline:
    push af
    push hl

    ;; Check if last line
    ld a, c
    cp 0x70         ; if on last line
    jp c, 1f
    call scroll     ; scroll instead of newline
    jp 2f
1:

    ld hl, 16
    add hl, bc      ; Increment by 16.
    ld b, h
    ld c, l

2:  pop hl
    pop af
    ret

;;; Carriage
;;;  BC: Offset into glyph buffer (in characters)
carriage:
    push af

    ld a, 0xF0
    and c
    ld c, a         ; Round to lower 16.

    pop af
    ret

;;; Scroll
;;;  DE: Base address of glyph buffer
;;;  BC: Offset into glyph buffer (in characters)
scroll:
    push af
    push hl
    push de
    push bc

    ;; Copy rows 1-7 to 0-6
    ld bc, 224
    ld hl, 32
    add hl, de
    ldir

    ;; Clear last row
    ld bc, 31
    ld h, d
    ld l, e
    ld (hl), 0x00
    inc de

    ldir

    pop bc
    pop de
    pop hl
    pop af
    ret

.global puts
;;; puts
;;;  Copies a string to the glyph buffer.
;;; Inputs:
;;;  DE: Base address of glyph buffer
;;;  BC: Offset into glyph buffer
;;;  IY: Text buffer (byte per character)
;;; Outputs:
;;;  BC: Ending address in glyph buffer
puts:
    push iy
    push hl
    push de
    push af
    di
        ;; Print each character in string
1:
        ;; Load character code
        ld a, (iy)
        ;; Check for NULL terminator
        cp 0
        jp z, 2f        ; If NULL, exit loop

        call putc       ; Put character in buffer.

        ;; Advance to next character
        inc iy
        jp 1b
2:
    ei
    pop af
    pop de
    pop hl
    pop iy
    ret

.global putg
;;; putg
;;;  Displays a character 5x6 glyph on the LCD.
;;; Inputs:
;;;  DE: Glyph to print
;;;  B: Starting line (in Pixels)
;;;  C: Starting column (in column)
;;; Outputs:
;;;  None
putg:
    push af
    push hl
    push bc
    push de
    ;; Test for NULL ptr.
    ld a, d
    cp 0
    jp nz, 1f

    ld a, e
    cp 0
    jp nz, 1f

    ld de, font   ; Print blank on null ptr.

1:
        ;; Setup Glyph Position
        di
        call init_text

        ;; Set column
        ld a, c
        add a, LCD_CMD_SETCOLUMN
        call lcd_busy_loop
        out (PORT_LCD_CMD), a

        ;; Set row
        ld a, b
        inc a
        add a, LCD_CMD_SETROW
        call lcd_busy_loop
        out (PORT_LCD_CMD), a

        ;; Draw Glyph loop
        push bc
        ld b,5          ; Glyphs are 5 rows tall
2:
        ld a, (de)

        call lcd_busy_loop
        out (PORT_LCD_DATA), a

        inc de          ; Advance to next row.
        djnz 2b         ; Next row, if b != 0
        pop bc

        ;; Set row back to initial position.
        ld a, b
        add a, LCD_CMD_SETROW
        call lcd_busy_loop
        out (PORT_LCD_CMD), a
        ei
3:  pop de
    pop bc
    pop hl
    pop af
    ret

.global display_glyphs
;;; display_graphic
;;;  Copies a glyph buffer to the LCD.
;;; Inputs:
;;;  DE: Glyph pointer buffer (2 bytes per glyph)
;;; NOTE:
;;;  Length is assumed to be 128 glyphs (256 bytes).
display_glyphs:
    push af
    push hl
    push de
    push bc

    ex de, hl                   ; HL now contains address of starting glyph pointer.
    ld bc, 0                    ; B - line, C - column

    ;; Glyph loop
1:
    ld d, (hl)
    inc hl
    ld e, (hl)                  ; DE now contains glyph pointer.
    inc hl                      ; HL now contains address of next glyph pointer.

    call putg

    inc c
    ld a, c

    ;; Check if newline.
    cp 0x10
    jp c, 1b                    ; If not, print next glyph

    ;; Advance to next line.
    ld c, 0
    ld a, b
    add a, 8
    ld b, a

    ;; Check if end of buffer
    cp 0x40
    jp c, 1b                    ; If not, print next glyph

    pop bc
    pop de
    pop hl
    pop af
    ret


.global display_graphic
;;; display_graphic
;;;  Copies a screen buffer to the LCD.
;;; Inputs:
;;;  IY: Screen buffer (bit per pixel)
display_graphic:
        push hl
        push bc
        push af
        push de
            di
            call init_graphic
            ld a, i
            push af
                ;; Swap IY into HL
                push iy
                pop hl

                ;; Set to row zero.
                ld a, LCD_CMD_SETROW
                call lcd_busy_loop
                out (PORT_LCD_CMD), a

                ;; Draw loop
                ld de, 12       ; 12 8-bit columns (96 pixels)
                ld a, LCD_CMD_SETCOLUMN
1:
                ;; Set to next column
                call lcd_busy_loop
                out (PORT_LCD_CMD),a

                ;; Draw column
                push af
                    ld b,64     ; 64 Rows in column
2:
                    ;; Draw row
                    ld a, (hl)
                    call lcd_busy_loop
                    out (PORT_LCD_DATA), a
                    add hl, de  ; hl += 12, to advance addr to next row.
                    djnz 2b     ; Next row, if b != 0.
                pop af
                ;; Reset to base address.
                dec h
                dec h
                dec h
                inc hl
                ;; Advance to next column
                inc a
                ;; Check if last column
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
;;; lcd_busy_loop
;;;  Waits for LCD to become ready.
lcd_busy_loop:
    push bc
    ld c, PORT_LCD_CMD
    ;; Wait for LCD to be ready.
1:
    in b, (c)    ; bit 7 set if LCD is busy
    jp m, 1b     ; repeat if bit 7 (sign bit) set.
    pop bc
    ret
