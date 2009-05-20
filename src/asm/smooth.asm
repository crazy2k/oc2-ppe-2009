extern screen_pixeles

section .data

w4: dw 4,4,4,4,4,4,4,4
mask_unos: db 1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,0
pack_pixel_word dq: 
blancos: dq -1, -1
negros: dq 0, 0

section .text

%include 'asm/macros_globales.inc'
%include 'asm/macros_pixels.inc'

%define ancho_sprite_bytes [ebp-4]
%define ancho_total_instancia [ebp-8]
%define linea_final [ebp-12]
%define cant_fila [ebp-16]
%define final [ebp-20]
%define offset_comienzo [ebp-24]

%define offset1 (SCREEN_W * 3)
%define offset2 offset1 * 2

%macro load_words 0-4 -3,3,0,0
	movdqu xmm0, [edi - offset1 + %3] ; superior
	punpcklbw xmm0,xmm7
	
	movdqu xmm1, [edi + %1]	; medio
	punpcklbw xmm1,xmm7
	movdqu xmm2, [edi + %2]
	punpcklbw xmm2,xmm7
	
	movdqu xmm3, [ebx + offset1 + %4] ;inferior
	punpcklbw xmm3,xmm7
%endmacro

%macro calc_proms 0-4 -3,3,0,0
	paddw xmm0, xmm1	;caculo la sumatoria de c/color
	paddw xmm0, xmm2
	paddw xmm0, xmm3

	psllw xmm0, xmm6 ;divido por 4 a c/color
%endmacro

global smooth

smooth:
;extern "C" bool smooth();
	entrada_funcion 0
	
	xor eax, eax
	xor ebx, ebx

	;1er caso (primera linea)



	;2do caso
	mov edi, [screen_pixeles]
	lea edi, [edi + offset1]

	pxor xmm7, xmm7; cargo ceros en xmm7
	movdqu xmm6, [w4]; cargo words de valor 4 en xmm6
	movdqu xmm5, [blancos]

primeros:

	load_words 0;3,0,0; cargo los primeros 8 bytes
	psrldq xmm1, 6; pongo el primer pixel en cero
	calc_proms
	movdqu xmm4, xmm0

	load_words 8-3,8+3,8,8; cargo los segundos 8 bytes
	calc_proms

;caculo de bls y ngrs
	packuswb xmm4, xmm0
	movdqu xmm0, xmm4

	pcmpeqw xmm4, xmm7
	movdqu xmm1, xmm4
	movdqu xmm2, xmm4

	psrldq xmm1, 1
	psrldq xmm2, 2
	
	pand xmm4, xmm1
	pand xmm4, xmm2
	
	

	pshufb xmm


	pcmpeqw xmm0, xmm5


;caculo de bls y ngrs

	movdqu xmm4, [edi]

	add edi,15

ciclo:


;3er caso (ultima linea)


salir:
	salida_funcion 0

