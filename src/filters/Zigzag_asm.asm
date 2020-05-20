global Zigzag_asm

Zigzag_asm:
	;ARIDAD: void Zigzag_asm(uint8_t *src, uint8_t *dst, int width, int height, int src_row_size, int dst_row_size)
	;RDI: src
	;RSI: dst
	;EDX: width
	;ECX: height
	;R8d: src_row_size 
	;R9d: dst_row_size
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15
	push rbx
	sub rsp, 8
	mov r12, rdi
	mov r13, rsi
	xor r14, r14
	xor r15, r15
	sub edx, 2
	sub ecx, 2
	%define current_pointer_src r12
	%define current_pointer_dst r13
	%define i r14d
	%define j r15d
	%define widthMinus2 edx  
	%define heightMinus2 ecx
	%define row_size r8
	lea rbx, [row_size * 2 + 8]
	add current_pointer_src, rbx
	add current_pointer_dst, rbx
	mov i, 2
	mov j, 2
	.rowLoop:
		cmp i, heightMinus2
		je .endRowLoop
		mov ebp, i
		shl rbp, 62
		shr rbp, 62
		cmp rbp, 1
		je .colLoopCasoB
		cmp rbp, 3
		je .colLoopCasoC
		;======== Caso A ======
		.colLoopCasoA:
			cmp j, widthMinus2
			je .endColLoopCasoA
			
			add current_pointer_dst, 16
			add current_pointer_src, 16
			add j, 4
			jmp .colLoopCasoA
		.endColLoopCasoA:
			mov j, 2
			inc i
			add current_pointer_dst, 16
			add current_pointer_src, 16
			jmp .rowLoop
		;======== Caso B ======
		.colLoopCasoB:
			cmp j, widthMinus2
			je .endColLoopCasoB

			movdqu xmm0, [current_pointer_src - 8]
			movdqu [current_pointer_dst], xmm0

			add current_pointer_dst, 16
			add current_pointer_src, 16
			add j, 4
			jmp .colLoopCasoB
		.endColLoopCasoB:
			mov j, 2
			inc i
			add current_pointer_dst, 16
			add current_pointer_src, 16
			jmp .rowLoop
		;======== Caso C ======
		.colLoopCasoC:
			cmp j, widthMinus2
			je .endColLoopCasoC

			movdqu xmm0, [current_pointer_src + 8]
			movdqu [current_pointer_dst], xmm0
			
			add current_pointer_dst, 16
			add current_pointer_src, 16
			add j, 4
			jmp .colLoopCasoC
		.endColLoopCasoC:
			mov j, 2
			inc i
			add current_pointer_dst, 16
			add current_pointer_src, 16
			jmp .rowLoop
	.endRowLoop:
	add rsp, 8
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp	
	ret
