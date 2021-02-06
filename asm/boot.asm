[BITS 16]
[ORG 0x7c00]

start:
    xor ax,ax   
    mov ds,ax
    mov es,ax  
    mov ss,ax
    mov sp,0x7c00

TestDiskExtension:
    mov [DriveId],dl ; dl holds driveId when BIOS transfers control to boot code
    mov ah,0x41
    mov bx,0x55aa
    int 0x13         ; if service is not supportd carry flag is set
    jc NotSupport
    cmp bx,0xaa55
    jne NotSupport

LoadLoader:
    mov si,ReadPacket
    mov word[si],0x10        ; structure length (16 bytes)
    mov word[si+2],5         ; number of sectors we want to read
    mov word[si+4],0x7e00    ; memory location (offset)
    mov word[si+6],0         ; segment part
    mov dword[si+8],1        ; source sector of loader (on disk) lower part
    mov dword[si+0xc],0      ; source sector of loader (on disk) higher part
    mov dl,[DriveId]         ; disk which will be used
    mov ah,0x42              ; use disk extension service
    int 0x13
    jc  ReadError            ; carry flag will be set if failed to read

    mov dl,[DriveId]         ; save driveId to use it in loader.asm
    jmp 0x7e00 

NotSupport:
ReadError:
    mov ah,0x13       ; function code (0x13 means print string)
    mov al,1          ; write mode (1 means cursor will be at the end of the string)
    mov bx,0xa        ; bx = bh+bl (bh-page number, bl-character attributes)
    xor dx,dx         ; dx = dh+dl (dh - rows, dl - columns)
    mov bp,Message    ; address of the string
    mov cx,MessageLen ; number of characters
    int 0x10          ; calling bios service

End:
    hlt    
    jmp End
     
DriveId:    db 0
Message:    db "We have an error in boot process"
MessageLen: equ $-Message
ReadPacket: times 16 db 0

times (0x1be-($-$$)) db 0 ; $$ - beggining of the current section (start of code)
                          ; $ - current position
                          ; $-$$ size from start of the code to the end of the message
                          ; 0x1be - start of the partition entries
	
times (16*4) db 0 ; there are 4 partition entries 16 bytes each
db 0x55               ; signature
db 0xaa               ; signature

	
