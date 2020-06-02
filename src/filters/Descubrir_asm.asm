section .rodata

align 16

mirrorMask: times 4 db 0x0C,0x0C,0x0C,0x00
srcMask: times 4 db 0x03,0x03,0x03,0x00

grayMask: times 4 db 0x01,0x00,0x00,0x00
alphaMask: times 4 db 0x00,0x00,0x00,0xFF

shuffleFinal: db 0x00,0x00,0x00,0x00,0x04,0x04,0x04,0x04,0x08,0x08,0x08,0x08,0x0C,0x0C,0x0C,0x0C

section .text

global Descubrir_asm
	;Aridad:
	;rdi: src
	;rsi: dst
	;edx: width
	;ecx: height

Descubrir_asm:

	push rbp
	mov rbp, rsp

	xor rax, rax
	mov eax, ecx
	mul edx
	shl rdx, 32
	or rax, rdx 	;rax: widht * height

	mov r8, rax
	shl r8, 2		;r8: cantidad total de bytes

	shr rax, 2
	mov rcx, rax	;rcx: cantidad de iteraciones

	mov r9, rdi
	add r9, r8
	sub r9, 16		;puntero para recorrer al reves

.mainLoop:
	
	movdqu xmm8, [rdi]	;src
	movdqu xmm9, [r9]	;mirror

	movdqa xmm10, [srcMask]
	pand xmm8, xmm10				

	movdqu xmm11, xmm9
	pshufd xmm9, xmm11, 00011011b		

	movdqa xmm10, [mirrorMask]
	pand xmm9, xmm10				
	psrlw xmm9, 2					

	pxor xmm8, xmm9					
									
	pxor xmm0, xmm0

	movdqa xmm10, [grayMask]

	;bit e7
	movdqu xmm11, xmm10
	pand xmm11, xmm8				
	pslld xmm11, 7
	por xmm0, xmm11					

	;bit e4
	movdqu xmm11, xmm10
	pslld xmm11, 1					
	pand xmm11, xmm8				
	pslld xmm11, 3
	por xmm0, xmm11					

	;bit e6
	movdqu xmm11, xmm10
	pslld xmm11, 8					
	pand xmm11, xmm8				
	psrld xmm11, 2
	por xmm0, xmm11					

	;bit e3
	movdqu xmm11, xmm10
	pslld xmm11, 9					
	pand xmm11, xmm8				
	psrld xmm11, 6
	por xmm0, xmm11					

	;bit e5
	movdqu xmm11, xmm10
	pslld xmm11, 16					
	pand xmm11, xmm8				
	psrld xmm11, 11
	por xmm0, xmm11					

	;bit e2
	movdqu xmm11, xmm10
	pslld xmm11, 17					
	pand xmm11, xmm8				
	psrld xmm11, 15
	por xmm0, xmm11					

	movdqa xmm11, [shuffleFinal]
	pshufb xmm0, xmm11

	movdqa xmm11, [alphaMask]
	por xmm0, xmm11

	movdqu [rsi], xmm0
	add rdi, 16
	add rsi, 16
	sub r9, 16
	dec rcx
	test rcx, rcx
	jnz .mainLoop

	pop rbp
	ret