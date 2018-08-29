.include "constants.inc.s"
.section .ktext
.global get_key
;; get_key
;;  Blocking read of next character.
;; Inputs:
;;  None
;; Outputs:
;;  A - Key value pressed
get_key:
    push bc

    ld c, PORT_KEYPAD
    ld d, 0xFE

1:  ld b, 0xFF          ; Reset the keypad.
    out (c), b

    rrc d               ; Select next group.
    out (c), d

    in a, (c)
    cp 0xFF
    jp z, 1b            ; Check next group if no key found.

    ld e, a

1:  ld b, 0xFF          ; Reset the keypad.
    out (c), b

    out (c), d

    in a, (c)
    cp 0xFF
    jp nz, 1b            ; Check next group if no key found.


    call map_key

    pop bc
    ret

.global map_key
map_key:
;; map_key
;;  maps keycode to character
;; Inputs:
;;  DE - raw key code pressed
;; Outputs:
;;  A - Key value pressed
    push hl
    push de

    ld h, 0
1:  inc h
    srl d
    jp c, 1b
    dec h

    ld a, 0
1:  inc a
    srl e
    jp c, 1b
    dec a

    sla h
    sla h
    sla h       ; H * 8 (3 bits to left)

    or h        ; Or A with H
    ld d, 0
    ld e, a
    ld hl, keymap ; HL now contains address of char code.
    add hl, de
    ld a, (hl)

    pop de
    pop hl
    ret

.section .kdata

.global keymap
;;; 0x00      = Invalid key, NULL
;;; 0x08      = Delete key, Backspace
;;; 0x0A      = Enter, Newline
;;; 0x0D      = Clear, Carriage Return
;;; 0x11      = Right
;;; 0x12      = Left
;;; 0x13      = Down
;;; 0x14      = Up
;;; 0x1B      = Mode key, Escape
;;; 0x20-0x30 = Non A-Z Characters.
;;; 0x40-0x7F = A-Z Characters.
;;; 0x80-0xFF = Modifier/Special Keys
keymap:
;;; Key0  Key1  Key2  Key3  Key4  Key5  Key6  Key7
.db 0x11, 0x13, 0x12, 0x14, 0x00, 0x00, 0x00, 0x00 ; Grp0
.db 0x00, 0x21, "W" , "R" , "M" , "H" , 0x0D, 0x00 ; Grp1
.db 0x0A, 0x40, "V" , "Q" , "L" , "G" , 0xFB, 0x00 ; Grp2
.db 0x3F, "Z" , "U" , "P" , "K" , "F" , "C" , 0xFC ; Grp3
.db 0x3A, "Y" , "T" , "O" , "J" , "E" , "B" , 0xFD ; Grp4
.db 0x20, "X" , "S" , "N" , "I" , "D" , "A" , 0xFE ; Grp5
.db 0xF5, 0xF4, 0xF3, 0xF2, 0xF1, 0xFF, 0x1B, 0x08 ; Grp6
.db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; Grp7
