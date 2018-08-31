.include "constants.inc.s"

.section .start
.org 0x0000
;; RST 0 = reboot
    jp startup
;; Magic Number
.db "WZ"

.org 0x0008
;; RST 8 = return to init
    jp init

;; .org 0x0038
;; RST 38 = On interupt
;   jp isr

.org 0x007F
.global startup
startup:
    di

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

    xor a ; Clear interrupts mask.
    out (PORT_INT_MASK), a

    ld a, 1 ; Init program in page 1
    out (PORT_BANKA), a

    ld a, 2 ; Data in page 2
    out (PORT_BANKB), a

    jp init
    rst 0 ; Prevent runaway code from unlocking flash

 ; .global isr
 ; isr:
 ;     di
 ;     push af
 ;     in a, (PORT_INT_MASK)
 ; 
 ;     bit BIT_INT_ON, a
 ;     jp nz, 1f
 ; 
 ;     xor INT_ON
 ;     out (PORT_INT_MASK), a
 ;     call poweroff
 ; 1:  
 ;     pop af
 ;     ei
 ;     reti
 ; 
 ; .global poweroff
 ; poweroff: 
 ;     push af
 ;     ;; Enable ON key interrupt and link port interrupt.
 ;     ;; Set low power on halt bit.
 ;     ld a, INT_ON | INT_LINK
 ;     out (PORT_INT_MASK), a
 ;     halt      ;; Enter low power mode (disabling various devices)
 ;               ;; and wait for an interrupt (either ON key or
 ;               ;; link activity) which will enable all hardware
 ;               ;; devices again.
 ;     ld a, INT_ON ;; Enable ON key, timer. Disable linkport.
 ;                  ;; Keep calculator powered.
 ;     out (PORT_INT_MASK), a
 ;     pop af
 ;     ret
