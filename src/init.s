.section .text
start:
    ld hl, message
    ld de, 0
    jr $

.section .data
message:
    .db "Hello, userspace!", 0
