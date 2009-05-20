extern screen_pixeles

section .data

mask_unos: dw 1,1,1,1,1,1,1,1
pack_pixel_word: dq 80_09_80_06_80_03_80_00h , 80_80_80_80_80_80_80_0Ch
blancos: dq -1,-1
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
	
	movdqu xmm3, [edi + offset1 + %4] ;inferior
	punpcklbw xmm3,xmm7
%endmacro

%macro calc_proms 0-4 -3,3,0,0
	paddw xmm0, xmm1	;caculo la sumatoria de c/color
	paddw xmm0, xmm2
	paddw xmm0, xmm3

	psrlw xmm0, 2 ;divido por 4 a c/color
%endmacro

%macro contar_colores 1
	pcmpeqw %1, xmm7
	movdqu xmm1, %1
	movdqu xmm2, %1

	psrldq xmm1, 1
	psrldq xmm2, 2
	
	pand %1, xmm1
	pand %1, xmm2

	movdqu xmm1, [pack_pixel_word]
	pshufb %1, xmm1
	movdqu xmm1, [mask_unos]
	pand %1, xmm1
	phaddw %1, %1
	phaddw %1, %1
	phaddw %1, %1
	
	movd edx, %1
	and edx, 0xFF
	
	add eax, edx
	
	neg edx
	add edx, 5
	
	add ebx, edx
%endmacro

global smooth

smooth:
;extern "C" bool smooth();
	entrada_funcion 0
	
	xor eax, eax				;pixels negros
	xor ebx, ebx				;pixels blancos

	;1er caso (primera linea)



	;2do caso
	mov edi, [screen_pixeles]
	lea edi, [edi + offset1]

	pxor xmm7, xmm7; cargo ceros en xmm7
	movdqu xmm6, [blancos]

	mov esi, SCREEN_H - 1 -1 
centrales:
	load_words 0;3,0,0; cargo los primeros 8 bytes
	pslldq xmm1, 6; pongo el primer pixel en cero
	calc_proms
	movdqu xmm4, xmm0; xmm4  = packed(xmm0) + packed(xmm4)

	load_words 8-3,8+3,8,8; cargo los segundos 8 bytes
	calc_proms
	packuswb xmm4, xmm0
	movdqu [edi], xmm4
	
	contar_colores xmm4
	add edi,15

	mov ecx, (SCREEN_W)/5 - 2; todos menos los 5 primeros y 5 ultimos 
ciclo:

	load_words ;-3,3,0,0; cargo los primeros 8 bytes
	calc_proms
	movdqu xmm4, xmm0

	load_words 8-3,8+3,8,8; cargo los segundos 8 bytes
	calc_proms
	packuswb xmm4, xmm0; xmm4  = packed(xmm0) + packed(xmm4)
	movdqu [edi],xmm4
	
;caculo de bls y ngrs
	
	contar_colores xmm4;, xmm7, eax; contar negros
	;contar_colores xmm0, xmm5, ebx; contar blancos

	add edi,15

	dec ecx
	jne ciclo
ultimos:
	load_words -3,0,0,0; cargo los primeros 8 bytes
	psrldq xmm2, 6; pongo el ultimo pixel en cero
	calc_proms
	movdqu xmm4, xmm0; xmm4  = packed(xmm0) + packed(xmm4)

	load_words 8-3,8+3,8,8; cargo los segundos 8 bytes
	calc_proms
	packuswb xmm4, xmm0
	movdqu [edi], xmm4
	
;caculo de bls y ngrs
	
	contar_colores xmm4;, xmm7, eax; contar negros
	;contar_colores xmm0, xmm5, ebx; contar blancos
	add edi,15

	dec esi
	jne centrales
	
	cmp eax, ebx
	
	mov eax, 0
	
	jbe salir
	
	mov eax, 1

;3er caso (ultima linea)


salir:
	salida_funcion 0

