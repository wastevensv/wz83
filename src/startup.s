.include "constants.inc.s"

.section .start
.org 0x0000
;; RST 0 = reboot
    jp startup
;; Magic Number - For my own amusement.
.db "WZ"

.org 0x0008
;; RST 8 = return to init
    jp init

; 0x0026 - Magic numbers for boot code.
.org 0x0026
.db 0x00

.org 0x0038
;; RST 38 = On interupt
    jp isr

; 0x0056 - Magic numbers for boot code.
.org 0x0056
.db 0xFF, 0xA5, 0xFF


.org 0x007F
.global startup
startup:
    di

    im 1

    ;; Re-map memory
    ld a, 3 << MEM_TIMER_SPEED
    out (PORT_MEM_TIMER), a

    ;; Set memory mapping
    ;; Bank 0: Flash Page 00
    ;; Bank 1: Flash Page *
    ;; Bank 2: RAM Page 01
    ;; Bank 3: RAM Page 00
    ld a, 1 | BANKB_ISRAM_CPU6
    out (PORT_BANKB), a

    ;; Set ram to zero.
    ld hl, 0x8000
    ld (hl), 0
    ld de, 0x8001
    ld bc, 0x7FFF
    ldir

    ld a, 0x1F ; Unlock program in page 0x1F
    out (PORT_BANKA), a

    ;; Unlock RAM and Flash
    call unlockFlash
    call unprotectRAM
    call unprotectFlash
    call lockFlash

    ;; Enable ON interrupt.
    xor a
    set BIT_INT_ON, a
    out (PORT_INT_MASK), a

    ld a, 1 ; Init program in page 1
    out (PORT_BANKA), a

    ld a, 2 ; Data in page 2
    out (PORT_BANKB), a

    jp init
    rst 0 ; Prevent runaway code from unlocking flash

.global isr
isr:
    di
    push af
    in a, (PORT_INT_TRIG)

    ;; Check if ON key triggered the interrupt
    bit BIT_INT_TRIG_ON, a
    jp z, 1f

    ;; Clear ON interrupt
    in a, (PORT_INT_MASK)
    res BIT_INT_ON, a
    out (PORT_INT_MASK), a

    ;; Set ON interrupt
    in a, (PORT_INT_MASK)
    set BIT_INT_ON, a
    out (PORT_INT_MASK), a
1:  
    pop af
    ei
    reti

.global poweroff
poweroff: 
    di
    push af

    ;; Disable the LCD
    ld a, LCD_CMD_SETDISPLAY
    out (PORT_LCD_CMD), a
    ;; Enable ON key interrupt.
    ;; Set low power on halt bit.
    xor a
    out (PORT_INT_MASK), a
    set BIT_INT_ON, a
    out (PORT_INT_MASK), a

    ei
    halt      ;; Enter low power mode (disabling various devices)
              ;; and wait for an interrupt (either ON key or
              ;; link activity) which will enable all hardware
              ;; devices again.
    di

    ;; Clear ON Interrupt.
    in a, (PORT_INT_MASK)
    res BIT_INT_ON, a
    out (PORT_INT_MASK), a
    ;; Re-Enable the LCD
    ld a, 1 + LCD_CMD_SETDISPLAY
    out (PORT_LCD_CMD), a
    pop af
    ei
    ret
