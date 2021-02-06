section .data

Gdt64:
    dq 0
    dq 0x0020980000000000
    dq 0x0020f80000000000        ; code segment descriptor for ring3 (DPL = 3)
    dq 0x0000f20000000000        ; data segment descriptor for ring3
TssDesc:
    dw TssLen-1
    dw 0                         ; address will be assigned in the code
    db 0
    db 0x89                      ; attribute field (DPL = 0)
    db 0
    db 0
    dq 0

Gdt64Len: equ $-Gdt64


Gdt64Ptr: dw Gdt64Len-1
          dq Gdt64

Tss:                    ; task state segment
    dd 0                ; 4 first bytes are reserved
    dq 0x150000         ; RSP0 (new address of RSP)
    times 88 db 0
    dd TssLen           ; IO permission map (not used)

TssLen: equ $-Tss

section .text
extern KMain            ; otherwise linker will not find it
global start            ; also for linker

start:
    lgdt [Gdt64Ptr]

SetTss:
    mov rax,Tss         ; loading TSS descriptor
    mov [TssDesc+2],ax
    shr rax,16
    mov [TssDesc+4],al
    shr rax,8
    mov [TssDesc+7],al
    shr rax,8
    mov [TssDesc+8],eax
    mov ax,0x20
    ltr ax              ; load task register

    
InitPIT:                        ; Programmable Interval Timer 
    mov al,(1<<2)|(3<<4)
    out 0x43,al                 ; writing to mode command register

    mov ax,11931                ; timer interval
    out 0x40,al                 ; writing to data register (channel 0)
    mov al,ah
    out 0x40,al

InitPIC:                         ; Programmable Interrupt Controller ??? 
    mov al,0x11                  ; initialization command 
    out 0x20,al                  ; address for the command register of the master chip
    out 0xa0,al                  ; slave

    mov al,32                    ; starting vector number of the first IRQ
    out 0x21,al                  ; data register for master
    mov al,40                    ; starting vector number for the slave is 40 (32 + 8)
    out 0xa1,al                  ; data register for slave

    mov al,4                     ; attaches slave chip to IRQ 2 of the master
    out 0x21,al
    mov al,2
    out 0xa1,al

    mov al,1                     ; selecting mode
    out 0x21,al
    out 0xa1,al

    mov al,11111110b             ; mask all the IRQs except the IRQ0 of the master which PIT uses
    out 0x21,al
    mov al,11111111b
    out 0xa1,al

    
    push 8              ; code segment selector (second entry of GDT)
    push KernelEntry
    db 0x48             ; by default return size is 32 bits, here we are overriding it to 48 bits
    retf

KernelEntry:
    mov rsp,0x200000    ; adjust stack pointer
    call KMain


End:
    hlt
    jmp End
