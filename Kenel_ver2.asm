%include "init1.inc"

[org 0x10000]
[bits 32]

PM_Start:
	mov bx, SysDataSelector
	mov ds, bx
	mov es, bx
	mov fs, bx
	mov gs, bx
	mov ss, bx
	
	lea esp, [PM_Start]
	
	mov edi, 0
	lea esi, [msgFMode]
	call print
	
	cld
	mov ax, SysDataSelector
	mov es, ax
	xor eax, eax
	xor ecx, ecx
	mov ax, 256
	mov edi, 0
	
loop_idt:
	lea esi, [idt_ignore]
	mov cx, 8
	rep movsb
	dex ax
	jnz loop_idt
	
	mov edi, 8*0x20
	lea esi, [idt_ignore]
	mov cx, 8
	rep movsb
	
	mov edi, 8*0x21
	lea esi, [idt_timer]
	mov cx, 8
	rep movsb
	
	lidt[idtr]

	mov al, 0xFC
	out 0x21, al
	sti
	jmp $

;------------------------------------------

printf:
	push eax
	push es
	mov ax, VideSelector
	mov es, ax
	
printf_loop:
	mov al, byte [esi]
	mov byte [es:edi], al
	inc edi
	mov byte [es:edi], 0x06
	inc esi
	inc edi
	or al, al
	jz printf_loop
	
printf_end:
	pop es
	pop eax
	ret
;----------------------------------------

MsgPMode db "Protected Mode", 0
msg_isr_ignore db "ingoreable interrupt", 0
msg_isr_32_timer db "timer interrupt", 0
msg_isr_33_keyboard db "Keyboard interrupt", 0

;----------------------------------------

isr_ignore:
	push gs
	push fs
	push es
	push ds
	pushad
	pushfd
	
	mov al, 0x20
	out 0x20, al
	
	mov ax, VideSelector
	mov es, ax
	mov edi, (80*7*2)
	lea esi, [msg_isr_ignore]
	call printf
	
	popfd
	popad 
	pop ds
	pop es
	pop fs
	pop gs
	
	iret
	
isr_32_timer:
	push gs
	push fs
	push es 
	push ds
	pushad
	pushfd
	
	mov al, 0x20
	out 0x20, al
	
	mov ax, VideSelector
	mov es, ax 
	mov edi, (80*2*2)
	lea esi, [msg_isr_32_timer]
	call printf
	inc byte [msg_isr_32_timer]
	
	popfd
	popad
	pop ds
	pop es
	pop fs
	pop gs 
	
	iret

isr_33_keyboard:
	pushad
	push gs 
	push fs
	push es
	push ds
	popad
	iret

;------------------------------------------

idtr:
	dw 256*8-1
	dd 0

idt_ignore:
	dw isr_ignore
	dw 0x08
	db 0
	db 0x8E
	dw 0x00001
	
idt_timer
	dw isr_32_timer
	dw 0x08
	db 0
	db 0x8E
	dw 0x00001

idt_keyboard
	dw isr_33_keyboard
	dw 0x08
	db 0
	db 0x8E
	dw 0x00001
	
times 512-($-$$) db 0