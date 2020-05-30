global Zigzag_asm

section .rodata

blue_green_mask: db 0x00, 0x80, 0x04, 0x80, 0x08, 0x80, 0x0c, 0x80, 0x01, 0x80, 0x05, 0x80, 0x09, 0x80, 0x0d, 0x80
red_alpha_mask: db 0x02, 0x80, 0x06, 0x80, 0x0a, 0x80, 0x0e, 0x80, 0x03, 0x80, 0x07, 0x80, 0x0b, 0x80, 0x0f, 0x80
fourth_pixel_mask: db 0x08, 0x80, 0x09, 0x80, 0xa, 0x80, 0x0b, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
first_pixel_mask: db 0x04, 0x80, 0x05, 0x80, 0x6, 0x80, 0x07, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
treinta_y_tres: dw 0x33, 0x33, 0x33, 0x1, 0x33, 0x33, 0x33, 0x1; 0x33 = 51 = 2^8 / 5
unos: db 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00, 0xff
pixeles_blancos: db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF 
dos_pixeles_blancos: db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
section .text

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
	movdqu xmm15, [blue_green_mask]
	movdqu xmm14, [red_alpha_mask]
	movdqu xmm13, [fourth_pixel_mask]
	movdqu xmm12, [first_pixel_mask]
	movdqu xmm11, [treinta_y_tres]
	movdqu xmm10, [unos]
	movdqu xmm9, [pixeles_blancos]
	movdqu xmm8, [dos_pixeles_blancos]
	pxor xmm6, xmm6
	%define blue_green_mask_ xmm15
	%define red_alpha_mask_ xmm14
	%define fourth_pixel_mask_ xmm13
	%define first_pixel_mask_ xmm12
	%define treinta_y_tres_ xmm11
	%define pixeles_blancos_ xmm9
	%define dos_pixeles_blancos_ xmm8
	%define unos_ xmm10
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
	.rowLoopCasoA:
		cmp i, heightMinus2
		jge .endRowLoopCasoA
		;======== Caso A ======|| i = 0 (mod 4) v i = 2 (mod 4)
		.colLoopCasoA:
			cmp j, widthMinus2
			je .endColLoopCasoA
			
			movdqu xmm0, [current_pointer_src - 8]
			movdqu xmm1, [current_pointer_src]

			movdqu xmm2, xmm0
			pshufb xmm2, blue_green_mask_; ||0g_3|0g_2|0g_1|0g_0||0b_3|0b_2|0b_1|0b_0||
			phaddsw xmm2, xmm2
			phaddsw xmm2, xmm2
			pslldq xmm2, 12
			psrldq xmm2, 12; ||--||--|G|B||

			movdqu xmm3, xmm0
			pshufb xmm3, red_alpha_mask_
			phaddsw xmm3, xmm3
			phaddsw xmm3, xmm3; ||-------|R||
			pslldq xmm3, 12
			psrldq xmm3, 8

			por xmm2, xmm3; ||---------|A|R|G|B||

			movdqu xmm3, xmm1
			pshufb xmm3, fourth_pixel_mask_; ||A|R|G|B||

			paddusw xmm2, xmm3; ||A|R|G|B|| A XMM2
			pslldq xmm2, 8
			psrldq xmm2, 8

			;=========
			movdqu xmm3, xmm1
			pshufb xmm3, blue_green_mask_; ||0g_3|0g_2|0g_1|0g_0||0b_3|0b_2|0b_1|0b_0||
			phaddsw xmm3, xmm3
			phaddsw xmm3, xmm3
			pslldq xmm3, 12
			psrldq xmm3, 12; ||--||--|G|B||

			movdqu xmm4, xmm1
			pshufb xmm4, red_alpha_mask_
			phaddsw xmm4, xmm4
			phaddsw xmm4, xmm4; ||-------|R||
			pslldq xmm4, 12
			psrldq xmm4, 8

			por xmm3, xmm4; ||---------|A|R|G|B||

			movdqu xmm4, xmm0
			pshufb xmm4, first_pixel_mask_; ||A|R|G|B||

			paddusw xmm3, xmm4; ||A|R|G|B|| A XMM3
			pslldq xmm3, 8

			por xmm2, xmm3

			pmullw xmm2, treinta_y_tres_
			psrlw xmm2, 8 
			packuswb xmm2, xmm2
			por xmm2, unos_

			movq [current_pointer_dst], xmm2

			;=========
			add current_pointer_dst, 8
			add current_pointer_src, 8
			add j, 2
			jmp .colLoopCasoA
		.endColLoopCasoA:
			mov j, 2
			add i, 2
			add current_pointer_dst, 16
			add current_pointer_dst, row_size
			add current_pointer_src, 16
			add current_pointer_src, row_size
			jmp .rowLoopCasoA
	.endRowLoopCasoA:
		mov current_pointer_src, rdi
		mov current_pointer_dst, rsi
		lea rbx, [row_size * 2 + 8]
		add current_pointer_src, rbx
		add current_pointer_dst, rbx
		add current_pointer_src, row_size
		add current_pointer_dst, row_size
		mov i, 3
		mov j, 2

	;======== Caso C ======|| i = 3 (mod 4)
	.rowLoopCasoC:
		cmp i, heightMinus2
		jge .endRowLoopCasoC
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
			add i, 4
			lea rbx, [row_size * 2]
			add current_pointer_dst, 16
			add current_pointer_dst, rbx
			add current_pointer_dst, row_size
			add current_pointer_src, 16
			add current_pointer_src, rbx
			add current_pointer_src, row_size
			jmp .rowLoopCasoC
	.endRowLoopCasoC:
		mov current_pointer_src, rdi
		mov current_pointer_dst, rsi
		lea rbx, [row_size * 4 + 8]
		add current_pointer_src, rbx
		add current_pointer_dst, rbx
		add current_pointer_src, row_size
		add current_pointer_dst, row_size
		mov i, 5
		mov j, 2	
	;======== Caso B ======|| i = 1 (mod 4)
	.rowLoopCasoB:
		cmp i, heightMinus2
		jg .endRowLoopCasoB
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
			add i, 4
			
			lea rbx, [row_size * 2]
			add current_pointer_dst, 16
			add current_pointer_dst, rbx
			add current_pointer_dst, row_size
			add current_pointer_src, 16
			add current_pointer_src, rbx
			add current_pointer_src, row_size

			jmp .rowLoopCasoB
	.endRowLoopCasoB:	
		
	;==========
	add edx, 2
	add ecx, 2
	%define width edx
	%define height ecx
	mov i, 0
	mov j, 0
	mov current_pointer_dst, rsi
	.rowLoopPaintSupBorder:
		cmp i, 2
		je .paintBottomBorder
		.colLoopPaintSupBorder:
			cmp j, width
			je .endColLoopPaintSupBorder
			movdqu [current_pointer_dst], pixeles_blancos_
			add j, 4
			add current_pointer_dst, 16
			jmp .colLoopPaintSupBorder
		.endColLoopPaintSupBorder:
			inc i
			mov j, 0
			jmp .rowLoopPaintSupBorder
	.paintBottomBorder:
		sub height, 2
		mov ebx, r8d
		imul ebx, height
		add height, 2
		mov current_pointer_dst, rsi
		add current_pointer_dst, rbx
		mov i, 0
		mov j, 0
		.rowLoopPaintBottomBorder:
		cmp i, 2
		je .paintSides
		.colLoopPaintBottomBorder:
			cmp j, width
			je .endColLoopPaintBottomBorder
			movdqu [current_pointer_dst], pixeles_blancos_
			add j, 4
			add current_pointer_dst, 16
			jmp .colLoopPaintBottomBorder
		.endColLoopPaintBottomBorder:
			inc i
			mov j, 0
			jmp .rowLoopPaintBottomBorder
	.paintSides:
	mov i, 0
	mov j, 0
	mov current_pointer_dst, rsi
	.rowLoopPaintSideBorder:
		cmp i, height
		je .end
		movq [current_pointer_dst], dos_pixeles_blancos_
		lea current_pointer_dst, [current_pointer_dst + row_size - 8] 
		movq [current_pointer_dst], dos_pixeles_blancos_
		add current_pointer_dst, 8
		inc i
		jmp .rowLoopPaintSideBorder
	.end:
	;==========
	add rsp, 8
	pop rbx
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp	
	ret