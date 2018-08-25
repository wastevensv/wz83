#include "kernel.inc"
    ; Program header
    .db "KEXC"
    .db KEXC_STACK_SIZE
    .dw 20
    .db KEXC_ENTRY_POINT
    .dw start
    .db KEXC_HEADER_END
start:
    pcall(getLcdLock)
    pcall(allocScreenBuffer)
    kld(hl, message)
    ld de, 0
    pcall(drawStr)
    pcall(fastCopy)
    jr $
message:
    .db "Hello, userspace!", 0
