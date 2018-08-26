; TI-8x constants
.macro define_mask name, bitN
    BIT_name .equ bitN \
    name .equ 1 << bitN
.endm

; Port numbers and outputs
    ; write
    PORT_MEM_TIMER      .equ 4
        define_mask(MEM_TIMER_MODE1, 0)
        define_mask(MEM_TIMER_SPEED, 1)
        ; 83+ SE/84+ only
        define_mask(MEM_TIMER_BATTERY, 6)
        
        
    PORT_RAM_PAGING     .equ 5
    
    PORT_BANKA          .equ 6
        ; 73/83+ BE only
        define_mask(BANKA_ISRAM_CPU6, 6)
        ; 83+ SE/84+ only
        define_mask(BANKA_ISRAM_CPU15, 7)
    
    PORT_BANKB          .equ 7
        ; 73/83+ BE only
        define_mask(BANKB_ISRAM_CPU6, 6)
        ; 83+ SE/84+ only
        define_mask(BANKB_ISRAM_CPU15, 7)
