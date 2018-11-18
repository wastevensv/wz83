.include "constants.inc.s"
.section .ktext
.global link_putc
;; putc
;;  Output a single byte over the link port.
;; Inputs:
;;  A: Byte to put.
;; Outputs:
;;  A: A <- 0 on success. A <- 1 on failure.
link_putc:  
    push bc
    push de
    ld c, a
    ld d, 0x01
put_bit:
    ld a, c
    and d
    or a
    jp nz, put1
    
put0:
    ld a, 1
    out (PORT_LINKPORT), a      ; Set tip low

    call wait_ring_low          ; Wait for ring to go low
    or a
    jp nz, 2f                   ; Fail on timeout

    ld a, 0
    out (PORT_LINKPORT), a      ; Set tip high

    call wait_ring_high         ; Wait for ring to go high
    or a
    jp nz, 2f                   ; Fail on timeout
    jp 1f

put1:
    ld a, 2
    out (PORT_LINKPORT), a      ; Set ring low

    call wait_tip_low           ; Wait for tip to go low
    or a
    jp nz, 2f                   ; Fail on timeout

    ld a, 0
    out (PORT_LINKPORT), a      ; Set ring high

    call wait_tip_high          ; Wait for tip to go high
    or a
    jp nz, 2f                   ; Fail on timeout

1:  rlc d                       ; Shift to next bit.
    ld a, d
    cp 1
    jp z, 3f                    ; If back at bit 0, successful.
    jp put_bit                  ; Transmit next bit.

2:  ld a, 1                     ; Fail
    jp 4f

3:  ld a, 0                     ; Succeed
4:  pop de
    pop bc                      ; Exit
    ret
    


;;; Helper routines to wait while avoiding lockup.
wait_tip_high:
    push bc
    ld b, 0xFF                  ; Load counter.

1:  in a, (PORT_LINKPORT)
    bit 0, a
    jp nz, 2f                   ; Jump to success.
    djnz 1b                     ; Try again till b == 0

    ld a, 1                     ; Fail case.
    jp 3f

2:  ld a, 0                     ; Success case.
3:  pop bc                      ; Exit
    ret

wait_tip_low:
    push bc
    ld b, 0xFF                  ; Load counter.

1:  in a, (PORT_LINKPORT)
    bit 0, a
    jp z, 2f                    ; Jump to success.
    djnz 1b                     ; Try again till b == 0

    ld a, 1                     ; Fail case.
    jp 3f

2:  ld a, 0                     ; Success case.
3:  pop bc                      ; Exit
    ret

wait_ring_high:
    push bc
    ld b, 0xFF                  ; Load counter.

1:  in a, (PORT_LINKPORT)
    bit 1, a
    jp nz, 2f                   ; Jump to success.
    djnz 1b                     ; Try again till b == 0

    ld a, 1                     ; Fail case.
    jp 3f

2:  ld a, 0                     ; Success case.
3:  pop bc                      ; Exit
    ret

wait_ring_low:
    push bc
    ld b, 0xFF                  ; Load counter.

1:  in a, (PORT_LINKPORT)
    bit 1, a
    jp z, 2f                    ; Jump to success.
    djnz 1b                     ; Try again till b == 0

    ld a, 1                     ; Fail case.
    jp 3f

2:  ld a, 0                     ; Success case.
3:  pop bc                      ; Exit
    ret
