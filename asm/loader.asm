[BITS 16]
[ORG 0x7e00]

start:
    mov [DriveId],dl      ; in boot.asm we saved driveId to dl

    mov eax,0x80000000    ; here we test whether cpuid supports 0x80000001 input value
    cpuid                 
    cmp eax,0x80000001    ; if eax < 0x80000001 thene cpuid doesn't support 0x80000001 input value
    jb NotSupport

    mov eax,0x80000001
    cpuid                 ; cpuid returns processor features in eax register
    test edx,(1<<29)      ; if 29-th bit is set then long mode is supported
    jz NotSupport
    test edx,(1<<26)      ; 26th bit means 1 GP page support
    jz NotSupport

LoadKernel:
    mov si,ReadPacket      ; kernel will be loaded to 0x10000
    mov word[si],0x10
    mov word[si+2],100     ; will be loading 100 sectors (100*512 = 50kb)
    mov word[si+4],0       ; offset (address = 0x1000*16+0 = 0x10000)
    mov word[si+6],0x1000  ; segment part of address
    mov dword[si+8],6      ; 0st sector - MBR; 1-5th - loader; so kernel starts in 6th
    mov dword[si+0xc],0
    mov dl,[DriveId]
    mov ah,0x42
    int 0x13
    jc  ReadError

GetMemInfoStart:
    mov eax,0xe820         ; service number
    mov edx,0x534d4150     ; ASCII code for smap
    mov ecx,20             ; length of memory block
    mov edi,0x9000         ; address to save memory block
    xor ebx,ebx
    int 0x15               ; if carry flag is set for the first call service e820 not availiable
    jc NotSupport

GetMemInfo:
    add edi,20             ; adjust address to save next memory block (20-length of the block)
    mov eax,0xe820
    mov edx,0x534d4150
    mov ecx,20
    int 0x15
    jc GetMemDone          ; if carry flag is set we reached end of memory block

    test ebx,ebx           ; check if ebx is zero
    jnz GetMemInfo

GetMemDone:
TestA20:                        ; A20 line allows to access addresses above 1mb
    mov ax,0xffff               ; in this block we test wether we could addes memory above 1mb
    mov es,ax
    mov word[ds:0x7c00],0xa200
    cmp word[es:0x7c10],0xa200
    jne SetA20LineDone
    mov word[0x7c00],0xb200     ; to exclude false positive doing second test
    cmp word[es:0x7c10],0xb200
    je End
    
SetA20LineDone:
    xor ax,ax
    mov es,ax
    
SetVideoMode:
    mov ax,3            ; text mode
    int 0x10            ; setup video mode
    
    cli                 ; disable interrupts when switching mode
    lgdt [Gdt32Ptr]     ; address of GDT is stored in dedicated register
    lidt [Idt32Ptr]     ; address of IDT is also stored in dedicated register

    mov eax,cr0         ; cr0 - control register (changes behaviour of the processer)
    or eax,1            ; set bit 0 to 1 which enables protected mode
    mov cr0,eax

    jmp 8:PMEntry       ; load code to cs register (8 is a selector)


ReadError:
NotSupport:
End:
    hlt
    jmp End

[BITS 32]
PMEntry:
    mov ax,0x10        ; address of data segment in GDT
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov esp,0x7c00

    cld                    ; finds a free memory and initialize a page
    mov edi,0x70000
    xor eax,eax
    mov ecx,0x10000/4
    rep stosd
    
    mov dword[0x70000],0x71007
    mov dword[0x71000],10000111b

    lgdt [Gdt64Ptr]

    mov eax,cr4
    or eax,(1<<5)       ; setting physical addres extension (PAE bit)
    mov cr4,eax

    mov eax,0x70000     ; address of the page structure (physycal address)
    mov cr3,eax         

    mov ecx,0xc0000080  ; index of extended feature enable register
    rdmsr
    or eax,(1<<8)       ; long mode enable bit
    wrmsr

    mov eax,cr0
    or eax,(1<<31)      ; enabling pageing
    mov cr0,eax

    jmp 8:LMEntry       ; code segment descriptor is 2-d entry in GDT

PEnd:
    hlt
    jmp PEnd

[BITS 64]
LMEntry:
    mov rsp,0x7c00      ; only set stack pointer

    cld                 ; clear direction flag. Move instruction will process data from low memory to 
                        ; high memory address, data copied in forward direction
    mov rdi,0x200000    ; destination address (we want to copy kernel here)
    mov rsi,0x10000     ; source address (where we loaded kernel)
    mov rcx,51200/8     ; counter (each iteration we will copy 8 bytes, kernel is 100 sectors * 512 bytes)
    rep movsq

    jmp 0x200000        ; jumping to kernel

LEnd:
    hlt
    jmp LEnd

DriveId:    db 0
ReadPacket: times 16 db 0


Gdt32:
    dq 0        ; first entry (8 bytes) of GDT is empty
Code32:         ; code segment descriptor
    dw 0xffff   ; size of code segment
    dw 0
    db 0
    db 0x9a     ; P(1) + DPL(00) + S(1) + TYPE(1010) = 0x9a
    db 0xcf     ; G(1) + D(1) + 0 + A(0) + LIMIT(1111) = 0xcf
    db 0
Data32:
    dw 0xffff
    dw 0
    db 0
    db 0x92
    db 0xcf
    db 0
    
Gdt32Len: equ $-Gdt32

Gdt32Ptr: dw Gdt32Len-1
          dd Gdt32

Idt32Ptr: dw 0
          dd 0

Gdt64:
    dq 0                    ; empty first record
    dq 0x0020980000000000   ; code segment, we don't need data segment because we don't jump to ring3, GDT and IDT will be reloaded in kernel

Gdt64Len: equ $-Gdt64


Gdt64Ptr: dw Gdt64Len-1
          dd Gdt64