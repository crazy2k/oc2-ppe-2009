%include "asm/macros_globales.inc"

extern screen_pixeles
extern colores
extern g_ver0
extern g_ver1
extern g_hor0
extern g_hor1

section .bss

%define size_buffer 16

bindex: resb size_buffer * 2
bindexiz2: resb size_buffer
bindexiz2m1: resb size_buffer
buff255mindex: resb size_buffer
color_fondo: resb size_buffer
ctes: resb size_buffer
fila_actual: resd 1

section .data

mod512: dd 01FFh,01FFh,01FFh,01FFh
b1: db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
w128: dw 80h,80h,80h,80h,80h,80h,80h,80h
compm64: db -65,-65,-65,-65,-65,-65,-65,-65,-65,-65,-65,-65,-65,-65,-65,-65
unos:
b255:
comp0: db -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
comp64: dw 63,63,63,63,63,63,63,63
comp128: db 127,127,127,127,127,127,127,127
comp192: db 191,191,191,191,191,191,191,191
mask: dw 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
offsets1: dw 00h,01h,02h,03h,04h,05h,06h,07h
offsets2: dw 08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh
copiar_sw: dw 0100h,0100h,0100h,0100h,0100h,0100h,0100h,0100h
unpack_comp: dq 02_02_01_01_01_00_00_00h, 80_04_04_04_03_03_03_02h 
mov_pixels: dq 05_04__80_03_02__80_01_00h, 80__80_09_08__80_07_06__80h
proldw: dq 0x03_02_01_00_0F_0E_0D_0C, 0x_0B_0A_09_08_07_06_05_04
prolw: dq 0x05_04_03_02_01_00_0F_0E, 0x_0D_0C_0B_0A_09_08_07_06
rep_color: dq 0x0100_020100_020100, 0x80_020100_020100_02
mask_origen: dq 0xFFFFFFFFFFFFFFFF, 0x00FFFFFFFFFFFFFF
mask_dest: dq 0x0000000000000000, 0xFF00000000000000

section	.text

%macro traer_colores_dw 1-3 xmm5, xmm7
	mov ebx, colores
	movdqu %2, [proldw]
	
	%rep 3
		movd eax, %1
		mov eax, [ebx + eax * 4]	
		movd %3, eax
		movss %1, %3
		pshufb %1, %2	
	%endrep
	xor eax, eax
	movd %3, eax
	movss %1, %3
	pshufb %1, %2
%endmacro

%macro traer_colores_w 1-3 xmm5, xmm7
    mov ebx, colores
	movdqu %2, [proldw]
	
	%rep 8
		movd eax, %1
		shr eax,16
		mov edx,[ebx + eax * 4]	
		shl edx,16
		
		movd eax, %1
		and eax, 0FFh
		or edx,[ebx + eax * 4]
		movd %3, edx
		movss %1, %3
		
		pshufb %1, %2	
	%endrep
%endmacro
    
global generarPlasma

%define i esi
%define j edi

%define rgb [ebp + 8]
%define res_parcial [ebp - 4]
generarPlasma:
    entrada_funcion 4
	
continuar:
    xor i, i
	
	mov eax, rgb
	movd xmm0, eax
	movdqu xmm1, [rep_color]
	pshufb xmm0, xmm1
	movdqu [color_fondo],xmm0
	
	mov ebx, [screen_pixeles]
	lea ebx, [ebx]
	mov [fila_actual], ebx
	
	movdqa xmm6, [copiar_sw] ;copia la mask de repeticion registro xmm6
	
	mov eax, [g_hor1]
	and eax, 0FFFFh
	movd xmm0, eax
	movss xmm7, xmm0
	pslldq xmm0, 4
	mov eax, [g_hor0]
	and eax, 0FFFFh
	movd xmm0, eax
	movss xmm7, xmm0
	pslldq xmm0, 4
	mov eax, [g_ver1]
	and eax, 0FFFFh
	movd xmm0, eax
	movss xmm7, xmm0
	pslldq xmm0, 4
	mov eax, [g_ver0]
	and eax, 0FFFFh
	movd xmm0, eax
	movss xmm7, xmm0
	movdqu xmm0 ,xmm7
	
loop_i:

    xor j, j
	
	movdqu xmm7, [ctes]
	pxor xmm0, xmm0
	movd xmm0, i
	pshufd xmm1, xmm0, 00_00_00_01B	; guardo en xmm1 i - i - i - 0
	pshufd xmm0, xmm0, 01_00_00_10B	; guardo en xmm0 0 - i - i - 0
	
	pslld xmm0, 1					; guardo en xmm0 0 - 2*i - 2*i - 0 
	paddd xmm0, xmm1				; guardo en xmm0 i - 3*i - 3*i - 0
	paddd xmm0, xmm7				; xmm0 (i - 3*i - 3*i - 0) + xmm7 (H1 + H0 + V1 + V0)
	
	pand xmm0, xmm6					; xmm0 = xmm0 % 512 (x c/dword)
	
	psrldq xmm0, 4					;borrar el primer dword de xmm0
	traer_colores_dw xmm0
	
	phaddd xmm0,xmm0
	phaddd xmm0,xmm0					
	movd edx, xmm0					;guardar el resultado parcial en ebx
	mov res_parcial, edx
	
loop_j:


calc_indices:
	
	movd xmm3, [ctes]					;cargo g_ver0 de ctes
	pshufb xmm3, xmm6				;copio en xmm3, g_ver0, en cada word
	
	movdqu xmm4, [mod512]			
	pshufb xmm4, xmm6				;copio en xmm4, 512, en cada word

;calculo de los indices
	xor ecx, ecx

indices_loop:
	lea eax, [j + ecx]
	movd xmm0, eax			
	pshufb xmm0, xmm6				;copio j en cada word de xmm0
	movdqu xmm2, [offsets1]			
	paddw xmm0, xmm2				;guardo en xmm0: j , j+1, j+2, j+4, j+5, ...
	movdqu xmm1, xmm0				;copio en xmm0 y xmm1, el valor de j, en cada word
	
	mov edx, res_parcial
	movd xmm2, edx
	pshufb xmm2, xmm6				;copio en cada word de xmm2, el resultado parcial para el valor de i actual
					
	psllw xmm0, 2					;mult por 4 a c/word
	paddw xmm0, xmm1
	paddw xmm0, xmm3				;sumo g_ver0 a c/word
	pand xmm0, xmm4					;hago modulo 512 de c/word
	traer_colores_w xmm0			;traigo los 8 colores calculados de memoria
		
	paddw xmm0, xmm2				;sumo a cada resultado el res parcial de i
	psrlw xmm0, 4					; >> 4, a cada index
	
	movdqu xmm2, [w128]
	paddw xmm0, xmm2				;sumo 128 en cada word
	movdqu xmm2, [mask]
	pand xmm0, xmm2					;me quedo con el byte menos significativo de cada word

	movdqu [bindex + ecx], xmm0		;guardo el primer valor calculado
	
	add ecx, 16
	cmp ecx, 16 * 2
	jb indices_loop

;calculos sobre los valores de indices
	movdqu xmm5, [bindex]			;tengo index en xmm0
	movdqu xmm1, [bindex + 16]		;tengo index2 en xmm1
	movdqu xmm4, xmm5
	movdqu xmm3, xmm1
	
	psllw xmm3,2
	psllw xmm4,2
	movdqu xmm2, [mask]
	pand xmm3, xmm2					;me quedo con el byte menos significativo de cada word
	pand xmm4, xmm2					;me quedo con el byte menos significativo de cada word
	
	packuswb xmm5, xmm1				;tengo los 16 index en xmm5
	packuswb xmm4, xmm3				;tengo (index << 2), en xmm4
	movdqu [bindexiz2], xmm4

	mov eax, 0101_0101h
	movd xmm3, eax
	pshufb xmm3, xmm6				;pongo en 1 cada byte de xmm3
	paddb xmm3, xmm4				;tengo ((index << 2) + 1), en xmm3
	movdqu [bindexiz2m1], xmm3
	
	movdqu xmm7, [b255]				;pongo en 255 cada byte de xmm3
	psubb xmm7, xmm3				;tengo 255 - ((index << 2) + 1), en xmm2
	movdqu [buff255mindex], xmm7

	mov ecx, 0
pixels_loop:
	
;Caso 3: 64 <= index < 128
;comparo mayor o igual a 64 ( > 63)	
	movdqu xmm0, xmm5
	movdqu xmm1, [comp64]
	pcmpgtb xmm0, xmm1
	movdqu xmm1, [unpack_comp]
	pshufb xmm0, xmm1			;tengo la mascara para este valor en xmm0
	
	movdqu xmm1, xmm3			;cargo ((index << 2) + 1)
	movdqu xmm4, [b255]
	punpcklbw xmm1,xmm4			;cargo 255
	movdqu xmm2, [mov_pixels]		
	pshufb xmm1, xmm2 			;configuro los 5 pixels dentro del registro
	pand xmm1, xmm0
	movdqu xmm4, xmm1				;dejo el resultado parcial en xmm4
	
	movdqu xmm2, xmm0			;guardo la mascara anterio negada en xmm2
	movdqu xmm1, [unos]
	pxor xmm2, xmm1

;Caso 4: 0 <= index < 64
;comparo mayor o igual a 0 ( > -1)	
	movdqu xmm0, xmm5
	movdqu xmm1, [comp0]
	pcmpgtb xmm0, xmm1
	movdqu xmm1, [unpack_comp]
	pshufb xmm0, xmm1			;tengo la mascara para este valor en xmm0
	pand xmm0, xmm2				;anulo los q ya tome con las mascaras anteriores
	
	movdqu xmm1, xmm7			;cargo 255 - ((index << 2) + 1)
	movdqu xmm2, [bindexiz2]
	punpcklbw xmm1,xmm2			;cargo (index << 2)
	movdqu xmm2, [mov_pixels]		
	pshufb xmm1, xmm2 			;configuro los 5 pixels dentro del registro
	pand xmm1, xmm0
	por xmm4, xmm1				;dejo el resultado parcial en xmm4
	
	movdqu xmm2, xmm0			;guardo la mascara anterior negada en xmm2
	movdqu xmm1, [unos]
	pxor xmm2, xmm1
	
	
;Caso 1  192 <= index < 255
;comparo mayor o igual a 191 ( > -65 )
	movdqu xmm0, xmm5
	movdqu xmm1, [compm64]
	pcmpgtb xmm0, xmm1
	movdqu xmm1, [unpack_comp]
	pshufb xmm0, xmm1
	pand xmm0, xmm2				;anulo los q ya tome con las mascaras anteriores
	
	movdqu xmm1, xmm3			;cargo ((index << 2) + 1)
	pxor xmm2, xmm2
	punpcklbw xmm1,xmm2			;cargo 0
	movdqu xmm2, [mov_pixels]		
	pshufb xmm1, xmm2 			;configuro los 5 pixels dentro del registro
	pand xmm1, xmm0
	por xmm4, xmm1				;dejo el resultado parcial en xmm4
	
	movdqu xmm2, xmm0			;guardo la mascara anterior negada en xmm2
	movdqu xmm1, [unos]
	pxor xmm2, xmm1
	
;Caso 2:  128 <= index < 192
	
	movdqu xmm1, xmm7			;cargo ((index << 2) + 1)
	punpcklbw xmm1,xmm7			;cargo ((index << 2) + 1)
	movdqu xmm2, [mov_pixels]		
	pshufb xmm1, xmm2 			;configuro los 5 pixels dentro del registro
	pand xmm1, xmm2
	por xmm4, xmm1				;dejo el resultado parcial en xmm4
	
	lea ebx, [j + j * 2]
	add ebx, [fila_actual]
	
	movdqu xmm1, [color_fondo]		;en xmm1 esta la mask con los pixels a utilizar
	movdqu xmm0, [ebx + ecx]		;en xmm0 estan los pixels leidos de pantalla
	pcmpeqb xmm1, xmm0				
	movdqu xmm2, [mask_origen]
	pand xmm2, xmm1					;elimino el byte del extremo del registro de la mascara
	
	movdqu xmm4, [unos]
		
	pand xmm4, xmm2
	
	movdqu xmm2, [unos]
	pxor xmm1, xmm2					;dejo en xmm1, la mask negada
	pand xmm0, xmm1
	
	por xmm4, xmm0
	
	movdqu [ebx + ecx], xmm4
	
	movdqu xmm4, [bindexiz2]
	
	psrldq xmm5, 5
	psrldq xmm4, 5
	psrldq xmm7, 5
	psrldq xmm3, 5
	
	add ecx, 15		; 15 bytes
	cmp ecx, 15 * 3
	jne pixels_loop
    
    add j, 15	; 15 pixels
    cmp j, SCREEN_W
    jl loop_j
	
	mov ebx, [fila_actual]
	add ebx, SCREEN_W * 3
	mov [fila_actual], ebx

    inc i
    cmp i, SCREEN_H - 1
    jl loop_i

    add word [g_ver0], 9
    add word [g_hor0], 8

    salida_funcion 4
