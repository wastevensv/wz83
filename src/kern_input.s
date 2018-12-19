.include "constants.inc.s"
.section .ktext

.global get_key
;;; get_key
;;;  Blocking read of next character.
;;; Inputs:
;;;  None
;;; Outputs:
;;;  A - Keycode
;;;  HL- Active keymap.
get_key:
    push hl
    push bc
    push de

    ld c, PORT_KEYPAD
    ld d, 0xFE

    ;; Reset the keypad.
1:  ld b, 0xFF
    out (c), b

    ;; Select and read next group.
    rrc d
    out (c), d
    in a, (c)
    cp 0xFF
    jp nz, 2f                   ; If key pressed, wait for release.

    ;; Check if back at first group.
    ld a, d
    cp 0xFE
    jp nz, 1b                   ; If not, continue.
    jp z, 4f                    ; If so, fail.

2:  ld e, a                     ; D, E = group, key

    ;; Reset the keypad.
3:  ld b, 0xFF
    out (c), b

    ;; Check if key released
    out (c), d
    in a, (c)
    cp 0xFF
    jp nz, 3b                   ; Wait until key released.

    push hl
    ;; Convert group+key to keycode.
        
    ;; Find active (low) group
    ld h, 0
1:  inc h
    srl d                       ; Shift D till 0
    jp c, 1b
    dec h

    ;; Find active (low) key
    ld a, 0                     ; Shift E till 0
1:  inc a
    srl e
    jp c, 1b
    dec a

    ;; Move bit 2-0 of H into bits 5-3 of A
    sla h
    sla h
    sla h                       ; H * 8 (3 bits to left)

    or h                        ; Or A with H
                                ; A now contains key map index
    pop hl


    ld d, 0
    ld e, a
    add hl, de
    ld a, (hl)                  ; A now contains char code.

    jp 5f

    ; Fail case: return NULL key.
4:  ld a, 0x00

5:  pop de
    pop bc
    pop hl
    ret

.section .kdata

;;; 0x00      = Invalid key, NULL
;;; 0x08      = Delete key, Backspace
;;; 0x0A      = Enter, Newline
;;; 0x0D      = Clear, Carriage Return
;;; 0x11      = Right
;;; 0x12      = Left
;;; 0x13      = Down
;;; 0x14      = Up
;;; 0x1B      = Mode key, Escape
;;; 0x20-0x3F = Non A-Z Characters.
;;; 0x40-0x7F = A-Z Characters.
;;; 0x80-0xFF = Modifier/Special Keys

.global keymap00
keymap00:
;;; Key0  Key1  Key2  Key3  Key4  Key5  Key6  Key7
.db 0x11, 0x13, 0x12, 0x14, 0x00, 0x00, 0x00, 0x00 ; Grp0
.db 0x0A, "+" , "-" , "*" , "/" , "^" , 0x0D, 0x00 ; Grp1
.db "-" , "3" , "6" , "9" , ")" , 0x00, 0xFB, 0x00 ; Grp2
.db "." , "2" , "5" , "8" , "(" , 0x00, 0x00, 0xFC ; Grp3
.db "0" , "1" , "4" , "7" , "," , 0x00, 0x00, 0xFD ; Grp4
.db 0x00, ">" , 0x00, 0x00, 0x00, 0x00, 0x00, 0xFE ; Grp5
.db 0xF5, 0xF4, 0xF3, 0xF2, 0xF1, 0xFF, 0x1B, 0x08 ; Grp6
.db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; Grp7

;;; Shift Keymap
.global keymap01
keymap01:
;;; Key0  Key1  Key2  Key3  Key4  Key5  Key6  Key7
.db 0x11, 0x13, 0x12, 0x14, 0x00, 0x00, 0x00, 0x00 ; Grp0
.db 0x0A, "+" , "[" , "]" , "/" , "^" , 0x0D, 0x00 ; Grp1
.db "-" , "3" , "6" , "9" , "}" , 0x00, 0xFB, 0x00 ; Grp2
.db "." , "2" , "5" , "8" , "{" , 0x00, 0x00, 0xFC ; Grp3
.db "0" , "1" , "4" , "7" , "," , 0x00, 0x00, 0xFD ; Grp4
.db 0x00, ">" , 0x00, 0x00, 0x00, 0x00, 0x00, 0xFE ; Grp5
.db 0xF5, 0xF4, 0xF3, 0xF2, 0xF1, 0xFF, 0x1B, 0x08 ; Grp6
.db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; Grp7

;;; Alpha Keymap
.global keymap10
keymap10:
;;; Key0  Key1  Key2  Key3  Key4  Key5  Key6  Key7
.db 0x11, 0x13, 0x12, 0x14, 0x00, 0x00, 0x00, 0x00 ; Grp0
.db 0x0A, 0x21, "w" , "r" , "m" , "h" , 0x0D, 0x00 ; Grp1
.db 0x3F, 0x40, "v" , "q" , "l" , "g" , 0xFB, 0x00 ; Grp2
.db 0x3A, "z" , "u" , "p" , "k" , "f" , "c" , 0xFC ; Grp3
.db 0x20, "y" , "t" , "o" , "j" , "e" , "b" , 0xFD ; Grp4
.db 0x00, "x" , "s" , "n" , "i" , "d" , "a" , 0xFE ; Grp5
.db 0xF5, 0xF4, 0xF3, 0xF2, 0xF1, 0xFF, 0x1B, 0x08 ; Grp6
.db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; Grp7

;;; Shift+Alpha Keymap
.global keymap11
keymap11:
;;; Key0  Key1  Key2  Key3  Key4  Key5  Key6  Key7
.db 0x11, 0x13, 0x12, 0x14, 0x00, 0x00, 0x00, 0x00 ; Grp0
.db 0x0A, 0x21, "W" , "R" , "M" , "H" , 0x0D, 0x00 ; Grp1
.db 0x3F, 0x40, "V" , "Q" , "L" , "G" , 0xFB, 0x00 ; Grp2
.db 0x3A, "Z" , "U" , "P" , "K" , "F" , "C" , 0xFC ; Grp3
.db 0x20, "Y" , "T" , "O" , "J" , "E" , "B" , 0xFD ; Grp4
.db 0x00, "X" , "S" , "N" , "I" , "D" , "A" , 0xFE ; Grp5
.db 0xF5, 0xF4, 0xF3, 0xF2, 0xF1, 0xFF, 0x1B, 0x08 ; Grp6
.db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; Grp7
