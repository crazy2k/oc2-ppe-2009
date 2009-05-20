%include "asm/macros_globales.inc"

extern screen_pixeles
extern colores
extern g_ver0
extern g_ver1
extern g_hor0
extern g_hor1

section .bss

%define size_buffer 80; (8 * 5) * 2

buffer: resb size_buffer

section .data

mod512: dd 01FFh,01FFh,01FFh,01FFh
b1: db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
w128: dw 80h,80h,80h,80h,80h,80h,80h,80h
compm64: db -65,-65,-65,-65,-65,-65,-65,-65,-65,-65,-65,-65,-65,-65,-65,-65
b255:
comp0: db -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
comp64: db 63,63,63,63,63,63,63,63,63,63,63,63,63,63,63,63
mask: dw 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
offsets1: dd 00h,01h,02h,03h,04h,05h,06h,07h
offsets2: dd 08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh
copiar_sw: dw 0100h,0100h,0100h,0100h,0100h,0100h,0100h,0100h

section	.text

%macro traer_colores_dw 2
    
%endmacro

%macro traer_colores_w 2
    
%endmacro

%macro color_de_fondo 3
    mov byte [%1 + %2], %3
%endmacro
    
global generarPlasma

%define i esi
%define j edi

%define rgb [ebp + 8]
%define indices [ebp - 4]
generarPlasma:
    entrada_funcion 16

;cargar buffer

continuar:
    xor i, i
	
	movdqu xmm5, [copiar_sw]
	movdqu xmm6, [mod512]
	movd xmm7, [g_hor1]
	pslldq xmm0, 4
	movd xmm7, [g_hor0]
	pslldq xmm0, 4
	movd xmm7, [g_ver1]
	pslldq xmm0, 4
	movd xmm7, [g_ver0]
	
loop_i:

    xor j, j
	
	pxor xmm0, xmm0
	movd xmm0, i
	pshufd xmm1, xmm0, 00_00_00_01B	; guardo en xmm1 i - i - i - 0
	pshufd xmm0, xmm0, 01_00_00_10B	; guardo en xmm0 0 - i - i - 0
	
	pslld xmm0, 1					; guardo en xmm0 0 - 2*i - 2*i - 0 
	paddd xmm0, xmm1				; guardo en xmm0 i - 3*i - 3*i - 0
	paddd xmm0, xmm7				; xmm0 (i - 3*i - 3*i - 0) + xmm7 (H1 + H0 + V1 + V0)
	
	pand xmm0, xmm6					; xmm0 = xmm0 % 512 (x c/dword)
	
	psrldq xmm0, 4					;borrar el primer dword de xmm0
	traer_colores_dw xmm0, 3
	
	phaddd xmm0,xmm0
	phaddd xmm0,xmm0					
	movd ebx, xmm0					;guardar el resultado parcial en ebx
	
loop_j:


calc_indices:

    movd xmm0, j					
	pshufb xmm0, xmm5				;copio j en cada word de xmm0
	
	movdqu xmm3, xmm7			
	pshufb xmm3, xmm5				;copio en xmm3, g_ver0, en cada word
	
	movdqu xmm4, xmm6
	pshufb xmm4, xmm5				;copio en xmm4, 512, en cada word

	;calculo de los 1ros 8 indices
	
	xor ecx, ecx

	movdqu xmm2, [offsets1]	
	paddw xmm0, xmm2				;guardo en xmm0: j , j+1, j+2, j+4, j+5, ...
	movdqu xmm1, xmm0				;copio en xmm0 y xmm1, el valor de j, en cada word
	
	movd xmm2, ebx
	pshufb xmm2, xmm5				;copio en cada word de xmm2, el resultado parcial para el valor de i actual
					
	psllw xmm0, 2					;mult por 4 a c/word
	paddw xmm0, xmm1
	paddw xmm0, xmm3				;sumo g_ver0 a c/word
	pand xmm0, xmm4					;hago modulo 512 de c/word
	traer_colores_w xmm0, 8			;traigo los 8 colores calculados de memoria
	paddw xmm0, xmm2				;sumo a cada resultado el res parcial de i
	psrlw xmm0, 4					; >> 4, a cada index
		
	movdqu xmm2, [w128]
	paddw xmm0, xmm2				;sumo 128 en cada word
	movdqu xmm2, [mask]
	pand xmm0, xmm2					;me quedo con el byte menos significativo de cada word

	movdqu indices, xmm0			;guardo el primer valor calculado

	;calculo de los 2dos 8 indices
	
	movd xmm0, j					
	pshufb xmm0, xmm5				;copio j en cada word de xmm0
	
	movdqu xmm2, [offsets2]
	paddw xmm0, xmm2				;guardo en xmm1: j+8 , j+9, j+A, j+B, j+C, ...
	movdqu xmm1, xmm0				;copio en xmm0 y xmm1, el valor de j, en cada word
	
	movd xmm2, ebx
	pshufb xmm2, xmm5				;copio en cada word de xmm2, el resultado parcial para el valor de i actual
					
	psllw xmm0, 2					;mult por 4 a c/word
	paddw xmm0, xmm1
	paddw xmm0, xmm3				;sumo g_ver0 a c/word
	pand xmm0, xmm4					;hago modulo 512 de c/word
	traer_colores_w xmm0, 8			;traigo los 8 colores calculados de memoria
	paddw xmm0, xmm2				;sumo a cada resultado el res parcial de i
	psrlw xmm0, 4					; >> 4, a cada index
	
	movdqu xmm2, [w128]
	paddw xmm0, xmm2				;sumo 128 en cada word
	movdqu xmm2, [mask]
	pand xmm0, xmm2					;me quedo con el byte menos significativo de cada word
	
	;copio todos los index al mismo reg
	movdqu xmm1, indices		
	
	packuswb xmm1,xmm0

;comparo mayor o igual a 64 ( > 63)	
	movdqu xmm0, xmm1
	movdqu xmm2, [comp64]
	pcmpgtb xmm0, xmm2

;comparo mayor o igual a 0 ( > -1)	
	movdqu xmm0, xmm1
	movdqu xmm2, [comp0]
	pcmpgtb xmm0, xmm2

;comparo mayor o igual a -64 ( > -65)
	movdqu xmm0, xmm1
	movdqu xmm2, [compm64]
	pcmpgtb xmm0, xmm2



    
    add j, 16
    cmp j, SCREEN_W
    jl loop_j
    
    mov dword res_mult, mult_invalid    ;resetear valor de mult    

    inc i
    cmp i, SCREEN_H
    jl loop_i

    add word [g_ver0], 9
    add word [g_hor0], 8

    salida_funcion 4
