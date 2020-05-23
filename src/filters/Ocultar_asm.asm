
MascaraRed: db 0x00, 0x0 , 0x00 ,0x0 ,0xFF ,0x0 ,0x0 ,0x0 ,0x0 ,0x0 ,0x0 ,0x00 ,0xFF ,0x0 ,0x0 ,0x0
MascaraGreen:db 0x00, 0x0 , 0xFF ,0x0 ,0x0 ,0x0 ,0x0 ,0x0 ,0x0 ,0x0 ,0xFF ,0x00 ,0x0 ,0x0 ,0x0 ,0x0
MascaraBlue: db 0xFF, 0x0 , 0x0 ,0x0 ,0x0 ,0x0 ,0x0 ,0x00 ,0xFF ,0x0 ,0x0 ,0x0 ,0x0 ,0x0 ,0x0 ,0x0
MascaraSacarUltimoBit: times 2 dq 1
MascaraSacarUltimos2BitsPorByte: times 4 dd 0b11111111_11111100_11111100_11111100
MascaraConservarUltimos2BitsPorByte: times 4 dd 0b00000000_00000011_00000011_00000011
MascaraInvertir: 	  db 0x0C,0x0D,0x0E,0x0F,0x08,0x09,0x0A,0x0B,0x04,0x05,0x06,0x07,0x00,0x01,0x02,0x03
MascaraCorregirBytes: db 0x00,0x02,0x02,0x02,0x08,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02,0x02

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
xor r14,r14 ; Le doy un uso super especifico al final, equivale a CANTIDAD DE COLUMNAS -17
xor r15,r15; (Lo uso en un momento para un offset)
xor r10,r10 ; puntero a final matriz SRC2, la uso para Espejo
xor rax,rax
;----
;Pongo en registros las etiquetas
movdqu xmm3, [MascaraRed]
movdqu xmm4, [MascaraGreen]
movdqu xmm5, [MascaraBlue]
movdqu xmm9, [MascaraSacarUltimoBit]
movdqu xmm2,[MascaraCorregirBytes]
mov r14d, ecx
sub r14d,17


mov rax,r9
imul eax, r8d  ;----> Final de la foto a copiar, va disminuyendo a medida que voy agregando fotos
sub eax,16
mov r10d,eax
add r10,rdx

ciclo:
;Aca empezaria el ciclo
pxor xmm7,xmm7; En xmm7 guardo el valor de color para los pixeles mas significativos
pxor xmm1,xmm1; En xmm1 guardo el valor de color para los pixeles menos significativos
xor rax,rax

;Consigo el valor de los 4 pixeles

; Offset de la fila
	mov eax,r9d   ; TAMANO FILA y dato 
	imul eax, r12d ; CONTADOR FILA 
	  
 ; Offset del dato
 	mov r15d,r13d ; contador columna 
 	shl r15d,2
 	add eax,r15d

	;copiamos el dato
	movdqu xmm8, [REG_SRC2+rax]
	pmovzxbw xmm15,xmm8  ; Extiendo los pixeles de la parte menos significativa 
	psrldq xmm8, 8 		; Corro 8 bytes para que quede la parte mas significativa en la parte menos significativa
	pmovzxbw xmm0,xmm8  ; Extiendo los pixeles de la parte mas significativa
	


movdqu xmm8,xmm15;XMM15 guarda una copia de XMMM
movdqu xmm6,xmm0 ;XMM6 guarda una copia de XMM0
;--
;Filtro GREEN 
pand xmm0,xmm4 ; En xmm0 me queda el valor de los green  
paddusw xmm7,xmm0 ; sume en vertical
paddusw xmm7, xmm7 ;Multiplico por dos 
movdqu xmm0,xmm6

pand xmm15,xmm4 ; En xmm0 me queda el valor de los green  
paddusw xmm1,xmm15 ; sume en vertical
paddusw xmm1, xmm1 ; Multiplico x dos
movdqu xmm15,xmm8

;Filtro RED 
pand xmm0,xmm3 ; En xmm0 me queda el valor de los red  
paddusw xmm7,xmm0 ; sume en vertical 
movdqu xmm0,xmm6

pand xmm15,xmm3 ; En xmm15 me queda el valor de los red  
paddusw xmm1,xmm15 ; sume en vertical
movdqu xmm15,xmm8
;FiltroBLUE:
pand xmm0,xmm5 ; En xmm0 me queda el valor de los blue 
paddusw xmm7,xmm0 ; sume en vertical
movdqu xmm0,xmm6

pand xmm15,xmm5; En xmm15 me queda el valor de los blue
paddusw xmm1,xmm15 ; sume en vertical
movdqu xmm15,xmm1



;-----------------------------------------------------------------------------------------------------------------------------------------------------
;Ya tengo los valores sumados invidualmente, haciendo dos sumas horizontales me queda en los 4 bytes menos significativos la sumas
phaddw xmm7,xmm7
phaddw xmm7,xmm7

phaddw xmm15,xmm15
phaddw xmm15,xmm15

verValor:
;Vuelvo a poner mis valores de forma que ocupen todo el registro y esten ordenados. 
pextrw rbx, xmm7,1
pmovzxbq xmm7,xmm7
pinsrw  xmm7,rbx,4

pextrw rbx, xmm15,1 
pmovzxbq xmm15,xmm15 
pinsrw  xmm15,rbx,4

		 															
;Divido por 4 en cada qword .
psrlq xmm7,2
psrlq xmm15,2 
;Ya tengo el valor de color 

;Ahora tengo que calcular los valores de bitsB, bitsG, bitsR

;-----------------------------------------------------+----------------------------------------------------------------------------------------------------------

;bitsB (DESPUES DE ESTO NO PUEDO VOLVER A USAR A XMM10 Y XMM1 PORQUE PIERDO EL VALOR)
movdqu xmm8,xmm7 ; Hago copia del color
psrlq xmm8, 4 ; Los corros cuatro bits porque es ese el que me interesa
pand xmm8, xmm9 ; Me quedo con el bit menos significativo. Lo demas esta en 0

movdqu xmm10, xmm8 ; Guardo en XMM10 (temporalmente) el valor de los ultimo
psllq xmm10, 1 ; Los corros un bit
movdqu xmm8, xmm7 ; Restauro la copia                                                           PARTE ALTA

psrlq xmm8, 7 ; los corros siete bits porque es ese el me que interesa
pand xmm8, xmm9; Me quedo con el ultimo bit ,xmm9 tiene un 1 por cada qword 

por xmm10,xmm8 ; Ahora tengo los ultimos menos significativos  2 bits de cada pixel. HIGH
;---------------------------------
movdqu xmm8,xmm15
psrlq xmm8,4
pand xmm8,xmm9

movdqu xmm1,xmm8 ; 																				PARTE BAJA
psllq xmm1,1
movdqu xmm8,xmm15

psrlq xmm8,7
pand xmm8, xmm9; Me quedo con el ultimo bit ,xmm9 tiene un 1 por cada qword 

por xmm1,xmm8 ; Ahora tengo los ultimos menos significativos  2 bits de cada pixel. LOW
;---------------------------
;bitsG
;xmm11 (DESPUES DE ESTO NO PUEDO VOLVER A USAR A USAR XMM11 y XMM6 PORQUE PIERDO EL VALOR)
movdqu xmm8,xmm7 ; Hago copia del color
psrlq xmm8, 3 ; Los corros tres bits porque es ese el que me interesa
pand xmm8, xmm9 ; Me quedo con el ultimo bit. Lo demas esta en 0

movdqu xmm11, xmm8 ; Guardo en XMM11 (temporalmente) el valor de el ultimo
psllq xmm11, 1 ; Los corros un bit 																PARTE ALTA
movdqu xmm8, xmm7 ; Restauro la copia     													           
 
psrlq xmm8, 6 ; los corros seis bits porque es ese el me que interesa
pand xmm8, xmm9; Me quedo con el ultimo bit ,xmm9 tiene un 1 por cada qword 

por xmm11,xmm8 ; Ahora tengo los ultimos 2 menos significativos bits de cada pixel. 
;--------------------------
movdqu xmm8,xmm15 ; Hago copia del color
psrlq xmm8, 3 ; Los corros tres bits porque es ese el que me interesa
pand xmm8, xmm9 ; Me quedo con el ultimo bit. Lo demas esta en 0

movdqu xmm6, xmm8 ; Guardo en XMM6 (temporalmente) el valor de el ultimo
psllq xmm6, 1 ; Los corros un bit
movdqu xmm8, xmm15 ; Restauro la copia 															PARTE BAJA
 
psrlq xmm8, 6 ; los corros seis bits porque es ese el me que interesa
pand xmm8, xmm9; Me quedo con el ultimo bit ,xmm9 tiene un 1 por cada qword 

por xmm6,xmm8 ; Ahora tengo los ultimos 2 menos significativos bits de cada pixel. 

;---------------------------
 
;bitsR (DESPUES DE ESTO NO PUEDO VOLVER A USAR A USAR XMM12 y XMM13 PORQUE PIERDO EL VALOR)
movdqu xmm8,xmm7 ; Hago copia del color
psrlq xmm8, 2 ; Los corros dos bits porque es ese el que me interesa
pand xmm8, xmm9 ; Me quedo con el ultimo bit. Lo demas esta en 0

		;																					     PARTE ALTA
movdqu xmm12, xmm8 ; Guardo en XMM12 (temporalmente) el valor de el ultimo
psllq xmm12, 1 ; Los corros un bit
movdqu xmm8, xmm7 ; Restauro la copia
 
psrlq xmm8, 5 ; los corros cinco bits porque es ese el me que interesa
pand xmm8, xmm9; Me quedo con el ultimo bit ,xmm9 tiene un 1 por cada qword 

por xmm12,xmm8 ; Ahora tengo los ultimos 2 bits de cada pixel. 


movdqu xmm8,xmm15 ; Hago copia del color
psrlq xmm8, 2 ; Los corros tres bits porque es ese el que me interesa
pand xmm8, xmm9 ; Me quedo con el ultimo bit. Lo demas esta en 0

movdqu xmm13, xmm8 ; Guardo en XMM6 (temporalmente) el valor de el ultimo
psllq xmm13, 1 ; Los corros un bit 																PARTE BAJA
movdqu xmm8, xmm15 ; Restauro la copia
 
psrlq xmm8, 5 ; los corros seis bits porque es ese el me que interesa
pand xmm8, xmm9; Me quedo con el ultimo bit ,xmm9 tiene un 1 por cada qword 

por xmm13,xmm8 ; Ahora tengo los ultimos 2 menos significativos bits de cada pixel. 


;----------------------------
;|xmm12 ->bitsR H 
;|xmm13 ->birsR L            
;|xmm11 ->bitsG H
;|xmm6  ->bitsG L	  
;|xmm10 ->bitsB H   
;|XMM1  ->bitsB L  
;---------------|---------------
;xmm3->[MascaraRed]
;xmm4->[MascaraGreen]
;xmm5->[MascaraBlue]
;xmm9->[MascaraSacarUltimoBit]
;------------------------------

;Ahora deberia sacar los valores para copiar a destiny

;ACORDATE QUE SRC ES EL OTRO DATO, VENGO TRABAJANDO CON SRC2 HASTA AHORA 
 									 
control:
movdqu xmm8 , [r10] ;XMM8 tiene el valor de SRC ESPEJO 
pshufb xmm8, [MascaraInvertir] ; SI DESPUES VEO QUE TENGO REGISTROS PARA PONERLO, MANDALE !!!!!!!!!!! 
psrld xmm8,2 ; Quiero los bits 2 y 3 
pand xmm8 , [MascaraConservarUltimos2BitsPorByte] ; XMM8 Ya limpiado excepto los bits 2 y 3 que ahora estan en 0 y 1 

;-----
; ;;

;Necesito acomodar la data para que cuando haga los XOR me quede parejo 

;----------------------------
;|xmm12 ->bitsR H  Hay que correrlo 64 + 16 bits para que quede en los bits 80 y 81
;|xmm13 ->birsR L  Hay que correrlo 16 bits, para que quede en el bit 16 y 17	           
;|xmm11 ->bitsG H  Hay que correrlo 64 + 8 bits para que quede en los bits 72 y 73
;|xmm6  ->bitsG L  Hay que correrlo 8 bits, para que quede en el bit 8 y 9	  
;|xmm10 ->bitsB H  Hay que correrlo 64 + 0 bits para que quede en los bits 64 y 65
;|XMM1  ->bitsB L  Esta bien porque va en la parte menos significativa, 0 y 1

pshufb xmm12 ,xmm2  ;
pshufb xmm13, xmm2 ; ------->	Como Los tenia distribuidos en qword los vuelvo a poner en como si fuesen 2 pixeles, tengo que correr el valor de byte 8 al lugar 4 
pshufb xmm11, xmm2
pshufb xmm6, xmm2
pshufb xmm10, xmm2
pshufb xmm1, xmm2

pslldq xmm10, 8 ; ------> Los corros a la parte alta del registro              
pslldq xmm11, 9
pslldq xmm12, 10

pslld xmm13,16
pslld xmm6,8

verFiltros:
;Ahora que ya estan corridos respectivamente, debo sumarlos 
paddusb xmm10,xmm11
paddusb xmm10,xmm12

paddusb xmm1,xmm6
paddusb xmm1,xmm13

paddusb xmm10,xmm1
;Ahora hago el XOR ENTRE  Espejo y BitsR/BitsG...
pxor xmm10,xmm8

;NECESITO UNA COPIA DE SRC Y SACARLE ULTIMOS DOS BITS
movdqu xmm15, [REG_SRC + rax]
pand xmm15, [MascaraSacarUltimos2BitsPorByte] ;           	                                            
paddsb xmm15,xmm10 ;AL FIN TENGO EL DATO !!!!!!!!!!!!!!!!!!!!!!!!!1
dato:
movdqu [REG_ACOPIAR+rax],xmm15
xor rax,rax
;Ahora hay que ver si tenemos que seguir ciclando o solo aumentar las variables con las que nos movemos

;Aumentar i / j 
 
	cmp r13d, r14d ; -> CONTADOR DE COLUMNAS MENOR A EL NUMERO DE COLUMNAS - 17 ()
	jl incCol  ; 
	incrementarFila:
	inc r12d
	cmp r12d,r8d
	je termine
	xor r13d,r13d 
	jmp ciclo

	incCol:
	sub r10,16
	add r13d,16
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
