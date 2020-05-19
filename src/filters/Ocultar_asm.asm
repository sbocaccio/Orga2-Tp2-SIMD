
MascaraRed: times 4 dd 0b00000000_11111111_00000000_00000000
MascaraGreen: times 4 dd 0b00000000_00000000_11111111_00000000
MascaraBlue: times 4 dd 0b00000000_00000000_00000000_11111111
MascaraSacarUltimoBit: times 4 dd 1
MascaraSacarUltimos2BitsPorByte: times 4 dd 0b11111111_11111100_11111100_11111100
MascaraConservarUltimos2BitsPorByte: times 4 dd 0b11111111_00000011_00000011_00000011
global Ocultar_asm
Ocultar_asm:
%define REG_SRC rdi
%define REG_SRC2 rsi
%define REG_ACOPIAR rdx
; RDI -> Puntero a src
; RSI -> Puntero a src2
; RDX -> Puntero a donde guardarFotoOculta
; ECX -> WIDTH ( ANCHO)
; r8d -> HEIGHT(ALTO)
; r9d -> TAMANO FILA SRC
; [rbp+24] / ebx -> TAMANO FILA DST  
push rbp
mov rbp,rsp
push rbx
mov ebx , [rbp+24]
push r12
push r13
push r14
push r15
;-------
xor rbx,rbx

xor r12,r12 ; CONTADOR FILA
xor r13,r13 ; CONTADOR COLUMNA
xor r14,r14 ; Le doy un uso super especifico al final, equivale a CANTIDAD DE COLUMNAS -1 
xor r15,r15; (Lo uso en un momento para un offset)
;----
;Pongo en registros las etiquetas
movdqu xmm3, [MascaraRed]
movdqu xmm4, [MascaraGreen]
movdqu xmm5, [MascaraBlue]
movdqu xmm9, [MascaraSacarUltimoBit]
mov r14d, ecx
sub r14d,5 


ciclo:
;Aca empezaria el ciclo
pxor xmm7,xmm7; En xmm7 guardo el valor de color. 
xor rax,rax

;Consigo el valor de los 4 pixeles



; Offset de la fila
	mov eax,r9d   ; TAMANO FILA y dato 
	imul eax, r12d ; CONTADOR FILA 
	;imul eax, 4 ; TAMANO POR DATO  
 
 ; Offset del dato
 	mov r15d,r13d ; contador columna 
 	imul r15d,4
 	add eax,r15d

	;copiamos el dato
	movdqu xmm15,[REG_SRC + rax]

; XMM15 TIENE SRC 


; Offset de la fila
	mov eax,r9d   ; TAMANO FILA  y dato
	imul eax, r12d ; CONTADOR FILA 
	;imul eax, 4 ; TAMANO POR DATO  
 
 ; Offset del dato
 	mov r15d,r13d ; contador columna 
 	imul r15d,4
 	add eax,r15d

	;copiamos el dato
	movdqu xmm0,[REG_SRC2 + rax]

; XMM0 TIENE SRC2

movdqu xmm6,xmm0 ;XMM6 guarda una copia de XMM0
;--
;Filtro GREEN 
pand xmm0,xmm4 ; En xmm0 me queda el valor de los green  
paddsb xmm7,xmm0 ; sume en vertical
pslld xmm7, 1 ;Multiplico por dos 
movdqu xmm0,xmm6

;Filtro RED 
pand xmm0,xmm3 ; En xmm0 me queda el valor de los red 
paddsb xmm7,xmm0 ; sume en vertical
movdqu xmm0,xmm6

;Filtro BLUE 
pand xmm0,xmm5 ; En xmm0 me queda el valor de los blue 
paddsb xmm7,xmm0 ; sume en vertical
movdqu xmm0,xmm6

;Ya tengo los valores sumados invidualmente, haciendo dos sumas horizontales me queda en los 4 bytes menos significativos la sumas
phaddw xmm7,xmm7
phaddw xmm7,xmm7

;Vuelvo a poner mis valores de forma que ocupen todo el registro y esten ordenados. 
pmovsxbd xmm7,xmm7
;Divido por 4 en cada byte.
psrld xmm7,2 
;Ya tengo el valor de color 

;Ahora tengo que calcular los valores de bitsB, bitsG, bitsR

;----------------------------

;bitsB (DESPUES DE ESTO NO PUEDO VOLVER A USAR A USAR XMM10 PORQUE PIERDO EL VALOR)
movdqu xmm8,xmm7 ; Hago copia del color
psrld xmm8, 4 ; Los corros cuatro bits porque es ese el que me interesa
pand xmm8, xmm9 ; Me quedo con el ultimo bit. Lo demas esta en 0

movdqu xmm10, xmm8 ; Guardo en XMM10 (temporalmente) el valor de el ultimo
pslld xmm10, 1 ; Los corros un bit
movdqu xmm8, xmm7 ; Restauro la copia
 
psrld xmm8, 7 ; los corros siete bits porque es ese el me que interesa
pand xmm8, xmm9; Me quedo con el ultimo bit ,xmm9 tiene un 1 por cada dword 

por xmm10,xmm8 ; Ahora tengo los ultimos 2 bits de cada pixel. 


;---------------------------
;bitsG
;xmm11 (DESPUES DE ESTO NO PUEDO VOLVER A USAR A USAR XMM11 PORQUE PIERDO EL VALOR)
movdqu xmm8,xmm7 ; Hago copia del color
psrld xmm8, 3 ; Los corros tres bits porque es ese el que me interesa
pand xmm8, xmm9 ; Me quedo con el ultimo bit. Lo demas esta en 0


movdqu xmm11, xmm8 ; Guardo en XMM11 (temporalmente) el valor de el ultimo
pslld xmm11, 1 ; Los corros un bit
movdqu xmm8, xmm7 ; Restauro la copia
 
psrld xmm8, 6 ; los corros seis bits porque es ese el me que interesa
pand xmm8, xmm9; Me quedo con el ultimo bit ,xmm10 tiene un 1 por cada dword 

por xmm11,xmm8 ; Ahora tengo los ultimos 2 bits de cada pixel. 

;---------------------------
 
;bitsR (DESPUES DE ESTO NO PUEDO VOLVER A USAR A USAR XMM12 PORQUE PIERDO EL VALOR)
movdqu xmm8,xmm7 ; Hago copia del color
psrld xmm8, 2 ; Los corros dos bits porque es ese el que me interesa
pand xmm8, xmm9 ; Me quedo con el ultimo bit. Lo demas esta en 0


movdqu xmm12, xmm8 ; Guardo en XMM12 (temporalmente) el valor de el ultimo
pslld xmm12, 1 ; Los corros un bit
movdqu xmm8, xmm7 ; Restauro la copia
 
psrld xmm8, 5 ; los corros cinco bits porque es ese el me que interesa
pand xmm8, xmm9; Me quedo con el ultimo bit ,xmm11 tiene un 1 por cada dword 

por xmm12,xmm8 ; Ahora tengo los ultimos 2 bits de cada pixel.
movdqu xmm8,xmm7 ; Hago copia del color 

;----------------------------
;|---------------|
;|xmm12 ->bitsR  |          
;|xmm11 ->bitsG	 | 
;|xmm10 ->bitsB  |    
;---------------|


;Ahora deberia sacar los valores para copiar a destiny

;DESTINY B: RECUERDO QUE EN XMM6 tengo una copia de XMM0, que tiene los valores ORIGINALES de los 4 pixeles que estoy modificando

;ACORDATE QUE SRC ES EL OTRO DATO, VENGO TRABAJANDO CON SRC2 HASTA AHORA 
; XMM15 TIENE SRC

pand xmm15, [MascaraSacarUltimos2BitsPorByte] ; (src[i][j].b & 0xFC) pero para todos

 ;-------------------------------------------------------------------------------------- 
 ;                       NO ESTAN GIRANDO LOS BYTES PARA QUE ESTE EN MODO ESPEJO		;
 ;																						;
 ;																						;	
 ;																						;
 ;																						;
 ;																						;
 ;--------------------------------------------------------------------------------------

 											;
 											;
 											;
 											;
 											;
 											;
    control:
											  
											  ; ((bitsB & 0x3) Ya lo tengo de ante
	xor rax,rax ; Limpio.. por si las dudas										  
	; Offset de la fila  src[(height-1)-i][(width-1)-j]
	mov eax,r8d  ; height
	dec eax      ;height-1                                          ; 
	sub eax,r12d ;height -1 -i  //CONTADOR FILA (CUAL QUIERO)
	imul eax, r9d ; TAMANO FILA  
	;imul eax, 4 ; TAMANO POR DATO  

 	; Offset del dato
 	mov r15d,ecx ;  width 
 	sub r15d,4 	 ;  width-4   ; Que dato quiero  --------------> Ese cuatro va ahi porque tengo que correr 4 para agarrar los 4  
 	sub r15d, r13d; width-1-j
 	lea rax, [rax + 4*r15]
	; Obtenemos el dato
 	movdqu xmm2 , [REG_SRC + rax] ;XMM2 tiene el valor de SRC 
 	movdqu xmm1, xmm2 ; Hago una copia de XMM16 (SRC) en XMM1

 
	psrld xmm2,2 ; Quiero los bits 2 y 3 
 	pand xmm2 , [MascaraConservarUltimos2BitsPorByte] ; XMM2 Ya limpiado excepto los bits 2 y 3 que ahora estan en 0 y 1 




;Necesito acomodar la data para que cuando haga los XOR me quede parejo 

;----------------------------
;|---------------|
;|xmm12 ->bitsR  |           	    PIXEL 1 							PIXEL 2 						     PIXEL 3 							       PIXEL 4 
;|xmm11 ->bitsG	 |  -> |xxxxxxxx|000000BR|000000BG|000000BB| |xxxxxxxx|000000BR|000000BG|000000BB| |xxxxxxxx|000000BR|000000BG|000000BB| |xxxxxxxx|000000BR|000000BG|000000BB| 
;|xmm10 ->bitsB  |    
;---------------|    A LO QUE QUIERO LLEGAR. 

;BitsB (XMM10) esta bien porque va en los ulitmos 
;BitsR (XMM12) hay que correrlo 16 bits a la izquierda , esto para cada pixel
;BitsG (XMM11) hay que correrlo 8 bits a la izquierda  , esto para cada PIXEL
pslld xmm12,16
pslld xmm11,8

;Ahora que ya estan corridos respectivamente, debo sumarlos 
paddb xmm10,xmm11
paddb xmm10,xmm12

;Ahora hago el XOR ENTRE  XMM10 y XMM2
pxor xmm10,xmm2

;Recuerdo que en XMM1 tengo una copia de SRC
pand xmm1, [MascaraSacarUltimos2BitsPorByte] ;           	    PIXEL 1 							PIXEL 2 						     PIXEL 3 							                 PIXEL 4 
                                             ;     -> |11111111|xxxxxx00|xxxxxx00|xxxxxx00| |11111111|xxxxxx00|xxxxxx00|xxxxxx00| |11111111|xxxxxx00|xxxxxx00|xxxxxx00| |11111111|xxxxxx00|xxxxxx00|xxxxxx00|

paddb xmm1,xmm10 ;AL FIN TENGO EL DATO !!!!!!!!!!!!!!!!!!!!!!!!!1

; Offset de la fila
	mov eax,r9d   ; TAMANO FILA y dato
	imul eax, r12d ; CONTADOR FILA 
	;imul eax, 4 ; TAMANO POR DATO  
 
 ; Offset del dato
 	mov r15d,r13d ; contador columna 
 	imul r15d,4
 	add eax,r15d

	;copiamos el dato
	movdqu [REG_ACOPIAR + rax],xmm1

;Ahora hay que ver si tenemos que seguir ciclando o solo aumentar las variables con las que nos movemos

;Aumentar i / j 
 
	cmp r13d, r14d ; -> CONTADOR DE COLUMNAS MENOR A EL NUMERO DE COLUMNAS - 1 
	jl incCol  ; 
	incrementarFila:
	inc r12d
	cmp r12d,r8d
	je termine
	xor r13d,r13d 
	jmp ciclo

	incCol:
	add r13d,4
	jmp ciclo


	termine:
	mov rax,rdx


;-------
pop r15                                          
pop r14
pop r13
pop r12
pop rbx   
pop rbp
ret
