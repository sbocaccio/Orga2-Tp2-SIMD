MascaraConseguirRojo:       db 0x02,0xFF,0xFF,0xFF,0x06,0xFF,0xFF,0xFF,0x0A,0xFF,0xFF,0xFF,0x0E,0xFF,0xFF,0xFF
MascaraConseguirGreen:      db 0x01,0xFF,0xFF,0xFF,0x05,0xFF,0xFF,0xFF,0x09,0xFF,0xFF,0xFF,0x0D,0xFF,0xFF,0xFF
MascaraConseguirBlue:       db 0x00,0xFF,0xFF,0xFF,0x04,0xFF,0xFF,0xFF,0x08,0xFF,0xFF,0xFF,0x0C,0xFF,0xFF,0xFF
MascaraConservarPrimerbit:  db 0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x00,0x00,0x00
MascaraConservarPrimer2bit: db 0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x02,0x00,0x00,0x00
MascaraSacarUltimos2Bits:   db 0xFC,0xFC,0xFC,0xFF,0xFC,0xFC,0xFC,0xFF,0xFC,0xFC,0xFC,0xFF,0xFC,0xFC,0xFC,0xFF
MascaraPatrones:            db 0xFF,0x00,0x00,0xFF,0x00,0xFF,0x00,0xFF,0x00,0x00,0xFF,0xFF,0xFF,0x00,0x00,0xFF
MascaraGrises:              db 0x00,0x00,0x00,0xFF,0x04,0x04,0x04,0xFF,0x08,0x08,0x08,0xFF,0x0C,0x0C,0x0C,0xFF
PonerAlpha:                 db 0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF
MascaraInvertir:            db 0x0C,0x0D,0x0E,0x0F,0x08,0x09,0x0A,0x0B,0x04,0x05,0x06,0x07,0x00,0x01,0x02,0x03
global Ocultar_asm
Ocultar_asm:
%define REG_SRC rdi
%define REG_SRC2 rsi
%define REG_ACOPIAR rdx
; RDI -> Puntero a src
; RSI -> Puntero a src2
; RDX -> Puntero a donde guardarFoto
; ECX -> WIDTH ( ANCHO)
; r8d -> HEIGHT(ALTO)
; r9d -> TAMANO FILA SRC
; [rbp+24] / ebx -> TAMANO FILA DST  
push rbp
mov rbp,rsp
push rbx
push r12
push r13
push r14
push r15
push r10
;-------
xor rbx,rbx
xor r12,r12 ; CONTADOR FILA
xor r13,r13 ; CONTADOR COLUMNA
xor r14,r14 ; Le doy un uso super especifico al final, equivale a CANTIDAD DE COLUMNAS -5
xor r15,r15; (Lo uso en un momento para un offset)
xor r10,r10 ; puntero a final de la foto la uso para Espejo
xor rax,rax
;-------
movdqu xmm3,[MascaraConseguirRojo]
movdqu xmm2,[MascaraConseguirGreen]            
movdqu xmm1,[MascaraConseguirBlue]
movdqu xmm0,[MascaraConservarPrimerbit]
movdqu xmm15,[MascaraSacarUltimos2Bits]
movdqu xmm13,[MascaraInvertir]
mov r14d, ecx
sub r14d,5        ;-> Debo continuar por cada fila hasta r14d

mov eax,r9d
imul eax, r8d  ;----> Final de la foto a SRC, va disminuyendo a medida que voy procesando pixeles pixeles
sub eax,16
mov r10d,eax


ciclo:

xor rax,rax
pxor xmm5,xmm5 ; Aca guardo la informacion de los pixeles,original
pxor xmm6,xmm6 ; Aca guardo en el primer byte por dword el color de cada pixel
pxor xmm7,xmm7 ; RojoBits 
pxor xmm8,xmm8 ; GreenBits
pxor xmm9,xmm9 ; AzulBits																			  
																											
												 	
;Consigo el valor de los 4 pixeles              
												 	
; Offset de la fila                            					
												
	mov eax,r9d   ; TAMANO FILA y dato 
	imul eax, r12d ; CONTADOR FILA 
	  
 ; Offset del dato
 	mov r15d,r13d ; contador columna 
 	shl r15d,2
 	add eax,r15d

	;copiamos el dato
	movdqu xmm4, [REG_SRC2+rax]
	movdqu xmm14,[REG_SRC +rax]

; Calculos de color:

;Green
movdqu xmm10,xmm4 ; Me hago una copia de los pixeles
pshufb xmm4,xmm2

movdqu xmm6,xmm4
paddw xmm6,xmm6

movdqu xmm4,xmm10 ;Restauro copia
;Red
pshufb xmm4,xmm3
paddw xmm6,xmm4
movdqu xmm4,xmm10 ;Restauro copia
;Blue
pshufb xmm4,xmm1
paddw xmm6,xmm4
movdqu xmm4,xmm10

;------- Me quedo en xmm4 el valor de el registro 
psrld xmm6, 2														
movdqu xmm10,xmm6 ; Me hago una copia de los colores ;          

;pshufb xmm6,xmm13 ;-> En este linea la convertirias en blanco y negro 								
BlueBits:																					
psrld xmm10,4 
pand xmm10, xmm0 ; -> consigo  bit 4 de cada dword
por xmm9,xmm10   ; -> consigo asigno los valores para bit 1 
pslld xmm9, 1    ; -> los corro al bit 1 de cada dword

movdqu xmm10,xmm6

psrld xmm10,7  
pand xmm10, xmm0 ; -> consigo  bit 7 de cada dword
por xmm9,xmm10 ; ; -> le asigno los valores para bit 0 

movdqu xmm10,xmm6; Restauro copia 

;Los 2 bits de cada dword ya estan alineados 

GreenBits:
psrld xmm10,3 
pand xmm10, xmm0 ; -> consigo  bit 3 de cada dword
pxor xmm8,xmm10   ; -> consigo asigno los valores para bit 1 
pslld xmm8, 1    ; -> los corro al bit 1 de cada dword

movdqu xmm10,xmm6 ; Restauro copia 

psrld xmm10,6  
pand xmm10, xmm0 ; -> consigo  bit 6 de cada dword
por xmm8,xmm10 ; ; -> le asigno los valores para bit 0 

movdqu xmm10,xmm6; Restauro la copia 

;Tengo que alinearlos a la posicion 8 de cada dword
pslld xmm8,8

RedBits:
psrld xmm10,2 
pand xmm10, xmm0 ; -> consigo  bit 2 de cada dword
por xmm7,xmm10   ; -> consigo asigno los valores para bit 1 
pslld xmm7, 1    ; -> los corro al bit 1 de cada dword

movdqu xmm10,xmm6

psrld xmm10,5
pand xmm10, xmm0 ; -> consigo  bit 6 de cada dword
por xmm7,xmm10 ; ; -> le asigno los valores para bit 0 

movdqu xmm10,xmm6

;Tengo que alinearlos a la posicion 16 de cada dword
pslld xmm8,16

;------- 
Imagen:
paddb xmm8,xmm7
paddb xmm8,xmm9
;----------------------- Ya tengo los colores de blanco y negro

;Pixeles Espejo
movdqu xmm11 , [REG_SRC + r10] ;XMM2 tiene el valor de SRC ESPEJO 
pshufb xmm11,xmm13 ; Los invierto
psrld xmm11,2          ; Los corro dos bits para sacar los 2 y 3 
pand xmm11, [MascaraConservarPrimer2bit] ; Me quedo con los bits que quiero

pxor xmm8,xmm11


;En xmm14 tengo la foto Que esconde

pand xmm14, xmm15 ; Limpio los 2 ultimos bits y copio
paddb xmm14,xmm8                              
movdqu [REG_ACOPIAR+rax],xmm14
xor rax,rax
;Ahora hay que ver si tenemos que seguir ciclando o solo aumentar las variables con las que nos movemos

;Aumentar i / j 
 
	cmp r13d, r14d ; -> CONTADOR DE COLUMNAS MENOR A EL NUMERO DE COLUMNAS - 5  ()
	jl incCol  ; 
	incrementarFila:
	inc r12d
	cmp r12d,r8d
	je termine
	xor r13,r13 
	jmp ciclo

	incCol:
	sub r10,16
	add r13d,4
	jmp ciclo


	termine:
	mov rax,rdx






;-------
pop r10
pop r15                                          
pop r14
pop r13
pop r12
pop rbx   
pop rbp
ret
