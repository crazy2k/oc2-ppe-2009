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

%macro load_n_words	1-5 -3,3,0,0
	%if %1 <> 1
		movdqu xmm0, [edi - offset1 + %4] ; superior
		punpcklbw xmm0,xmm7
	%endif

	%if %1 <> 3
		movdqu xmm1, [edi + %2]	; medio
		punpcklbw xmm1,xmm7
	%endif
	
	%if %1 <> 4
		movdqu xmm2, [edi + %3]
		punpcklbw xmm2,xmm7
	%endif
	
	%if %1 <> 2
		movdqu xmm3, [edi + offset1 + %5] ;inferior
		punpcklbw xmm3,xmm7
	%endif
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

%macro aplicar_filtro 2; %1 en [principio,medio, final], %2 en [0,1,2]
	%ifidni %1,principio
		load_n_words %2,0,3,0,0; cargo los primeros 8 bytes  ;*
		pslldq xmm1, 6; pongo el primer pixel en cero   ;*
	%else
		load_n_words %2;-3,3,0,0; cargo los primeros 8 bytes ;*
	%endif
	
	%if %2 <> 1
		paddw xmm2, xmm0
	%endif
	paddw xmm2, xmm1
	%if %2 <> 2
		paddw xmm2, xmm3
	%endif
	psrlw xmm2, 2 ;divido por 4 a c/color
	
	movdqu xmm4, xmm2
	
	%ifidni %1,final
		load_n_words %2,8-3,8+3-3,8,8; cargo los segundos 8 bytes ;*
		psrldq xmm2, 6; pongo el ultimo pixel en cero   ;*
	%else
		load_n_words %2,8-3,8+3,8,8; cargo los segundos 8 bytes
	%endif

	%if %2 <> 1
		paddw xmm2, xmm0
	%endif
	paddw xmm2, xmm1
	%if %2 <> 2
		paddw xmm2, xmm3
	%endif
	psrlw xmm2, 2 ;divido por 4 a c/color

	packuswb xmm4, xmm2; xmm4  = packed(xmm0) + packed(xmm4)
	%ifidni %1,final
		%if %2 == 2
			movdqu xmm0,xmm4
		%else
			movdqu [edi],xmm4
		%endif
	%else
		movdqu [edi],xmm4
	%endif
	
	contar_colores xmm4;, xmm7, eax; contar negros
	add edi,15
%endmacro

global smooth

smooth:
;extern "C" bool smooth();
	entrada_funcion 0
	
	xor eax, eax				;pixels negros
	xor ebx, ebx				;pixels blancos

	mov edi, [screen_pixeles]
	lea edi, [edi]
	pxor xmm7, xmm7; cargo ceros en xmm7
	movdqu xmm6, [blancos]

;1er caso (primera linea)
	aplicar_filtro principio,1
	mov ecx, (SCREEN_W)/5 - 2; todos menos los 5 primeros y 5 ultimos 
pciclo:
	aplicar_filtro medio,1
	
	dec ecx
	jne pciclo
pultimos:
	aplicar_filtro final,1
	
;2do caso (centro)
	mov esi, SCREEN_H - 1 -1 
centrales:
	aplicar_filtro principio,0

	mov ecx, (SCREEN_W)/5 - 2; todos menos los 5 primeros y 5 ultimos 
cciclo:
	aplicar_filtro medio,0

	dec ecx
	jne cciclo
cultimos:
	aplicar_filtro final,0
	
	dec esi
	jne centrales
	
;3er caso (ultima linea)
	aplicar_filtro principio,2
	mov ecx, (SCREEN_W)/5 - 2; todos menos los 5 primeros y 5 ultimos 
uciclo:
	aplicar_filtro medio,2
	
	dec ecx
	jne uciclo
uultimos:
	aplicar_filtro final,2
	sub edi, 15 + 1
	mov edx, [edi]
	and edx, 0FFh
	pxor xmm1, xmm1
	movd xmm1, edx
	pslldq xmm0,1
	
	por xmm0,xmm1
	movdqu [edi], xmm0
	
	cmp eax, ebx
	mov eax, 0
	jbe salir
	mov eax, 1


salir:
	salida_funcion 0

