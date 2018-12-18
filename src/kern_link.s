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
    ld c, a                     ; Keep original A in C
    ld d, 0x01                  ; D is bit mask
    ;; Cycle through bits of A
put_bit:
    ;; Test if bit is 0 or 1
    ld a, c
    and d
    or a
    jp nz, put1
    
put0:
    ;; Output a zero
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
    ;; Output a one
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

    ;; Shift to next bit
1:  rlc d
    ld a, d

    ;; Check if mask looped back to bit 0
    cp 1
    jp z, 3f                    ; If back at bit 0, successful.

    jp put_bit                  ; Transmit next bit.

    ;; Fail
2:  ld a, 0                     ; Set both lines high.
    out (PORT_LINKPORT), a
    ld a, 1
    jp 4f

    ;; Succeed
3:  ld a, 0

    ;; Exit
4:  pop de
    pop bc                      ; Exit
    ret
    


;;; Helper routines to wait while avoiding lockup.
wait_tip_high:
    push bc
    ld b, 0xFF                  ; Load counter.

    ;; Loop till bit 0 is set, or timeout
1:  in a, (PORT_LINKPORT)
    bit 0, a
    jp nz, 2f                   ; Jump to success.
    djnz 1b                     ; Try again till b == 0

    ;; Fail
    ld a, 1
    jp 3f

    ;; Success
2:  ld a, 0
    ;; Exit
3:  pop bc
    ret

wait_tip_low:
    push bc
    ld b, 0xFF                  ; Load counter.

    ;; Loop till bit 0 is reset, or timeout
1:  in a, (PORT_LINKPORT)
    bit 0, a
    jp z, 2f                    ; Jump to success.
    djnz 1b                     ; Try again till b == 0

    ;; Fail
    ld a, 1
    jp 3f

    ;; Success
2:  ld a, 0
    ;; Exit
3:  pop bc
    ret

wait_ring_high:
    push bc
    ld b, 0xFF                  ; Load counter.

    ;; Loop till bit 1 is set, or timeout
1:  in a, (PORT_LINKPORT)
    bit 1, a
    jp nz, 2f                   ; Jump to success.
    djnz 1b                     ; Try again till b == 0

    ;; Fail
    ld a, 1
    jp 3f

    ;; Success
2:  ld a, 0
    ;; Exit
3:  pop bc
    ret

wait_ring_low:
    push bc
    ld b, 0xFF                  ; Load counter.

    ;; Loop till bit 1 is reset, or timeout
1:  in a, (PORT_LINKPORT)
    bit 1, a
    jp z, 2f                    ; Jump to success.
    djnz 1b                     ; Try again till b == 0

    ;; Fail
    ld a, 1
    jp 3f

    ;; Success
2:  ld a, 0
    ;; Exit
3:  pop bc
    ret

