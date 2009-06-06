; void negative()

%include 'asm/macros_globales.inc'

extern screen_pixeles

global  negative

ceros: dq 0x0000000000000000, 0x0000000000000000
uno: dq 0x0000000000000001, 0x0000000000000000
dos55_replicado: dq 0x000000FF000000FF, 0x000000FF000000FF
reordenar_words_0: dq 0x808080800C080400, 0x8080808080808080
reordenar_words_1: dq 0x0C08040080808080, 0x8080808080808080
reordenar_words_4: dq 0x8080808080808080, 0x808080800C080400
reordenar_words_5: dq 0x8080808080808080, 0x0C08040080808080
dos55_32: dd 0x000000FF

; asume que en edi se encuentra el puntero al primero de los 5 pixeles
; actuales; 
%macro procesar_pixels 1 ; puede ser: primera_fila, centro, ultima_fila


	%ifnidni %1,primera_fila    ; si no es la primera fila,
        movdqu xmm0, [edi - SCREEN_W*3]
    %elifnidni
        movdqu xmm0, [ceros]
    %endif

    movdqu xmm1, [edi - 3]
    movdqu xmm2, [edi + 3]

	%ifnidni %1,ultima_fila    ; si no es la ultima fila,
        movdqu xmm3, [edi + SCREEN_W*3]
    %elifnidni
        movdqu xmm3, [ceros]
    %endif
   
    ; hasta aca, tengo xmmi = [R|BGR|BGR|BGR|BGR|BGR]
    ; (una posicion es un byte)

    movdqu xmm4, xmm0
    movdqu xmm5, xmm1
    movdqu xmm6, xmm2
    movdqu xmm7, xmm3       ; xmmi = [R|BGR|BGR|BGR|BGR|BGR]
                            ; (una posicion es un byte)

    ; partes bajas
    punpcklbw xmm0, [ceros] 
    punpcklbw xmm1, [ceros]
    punpcklbw xmm2, [ceros] 
    punpcklbw xmm3, [ceros] ; xmmi = [(0G)(0R)|0B0G0R|0B0G0R]

    ; partes altas
    punpckhbw xmm4, [ceros] 
    punpckhbw xmm5, [ceros]
    punpckhbw xmm6, [ceros] 
    punpckhbw xmm7, [ceros] ; xmmi = [(0R)|(0B)(0G)(0R)|(0B)(0G)(0R)|(0B)]


    paddw xmm0, xmm1
    paddw xmm0, xmm2
    paddw xmm0, xmm3
    paddw xmm0, [uno]       ; xmm0 = sup(c1) + inf(c1) + sig(c1) + ant(c1) + 1

    paddw xmm4, xmm5
    paddw xmm4, xmm6
    paddw xmm4, xmm7
    paddw xmm4, [uno]       ; xmm4 = sup(c1) + inf(c1) + sig(c1) + ant(c1) + 1

    ; a esta altura ya tengo libres: xmm1, xmm2, xmm3, xmm5, xmm6, xmm7

    movdqu xmm1, xmm0
    movdqu xmm5, xmm4
    punpcklwd xmm0, [ceros]
    punpckhwd xmm1, [ceros]
    punpcklwd xmm4, [ceros]
    punpckhwd xmm5, [ceros]

    ; ahora solo tengo libres xmm2, xmm3, xmm6, xmm7

    cvtdq2ps xmm0, xmm0
    cvtdq2ps xmm1, xmm1
    cvtdq2ps xmm4, xmm4
    cvtdq2ps xmm5, xmm5

    rsqrtps xmm0, xmm0
    rsqrtps xmm1, xmm1
    rsqrtps xmm4, xmm4
    rsqrtps xmm5, xmm5

    movdqu xmm2, [dos55_replicado]
    cvtdq2ps xmm2, xmm2

    mulps xmm0, xmm2
    mulps xmm1, xmm2
    mulps xmm4, xmm2
    mulps xmm5, xmm2

    cvtps2dq xmm0, xmm0
    cvtps2dq xmm1, xmm1
    cvtps2dq xmm4, xmm4
    cvtps2dq xmm5, xmm5


    pshufb xmm0, [reordenar_words_0]
    pshufb xmm1, [reordenar_words_1]
    pshufb xmm4, [reordenar_words_4]
    pshufb xmm5, [reordenar_words_5]
    por xmm0, xmm1
    por xmm0, xmm4
    por xmm0, xmm5

    movdqu [edi], xmm0

%endmacro

%macro procesar_byte 2 ; puede ser: (primero,ultimo,medio);(arriba,abajo,medio)
    xor eax, eax
    xor edx, edx
	%ifnidni %1,primero
        mov edx, [edi - 3]
        and edx, 0x000000FF
        add eax, edx
    %endif
	%ifnidni %1,ultimo
        mov edx, [edi + 3]
        and edx, 0x000000FF
        add eax, edx
    %endif
	%ifnidni %2,arriba
        mov edx, [edi - SCREEN_W*3]
        and edx, 0x000000FF
        add eax, edx
    %endif
	%ifnidni %2,abajo
        mov edx, [edi + SCREEN_W*3]
        and edx, 0x000000FF
        add eax, edx
    %endif

    inc eax

    mov aux, eax
    finit
    fild dword aux
    fsqrt
    fld1            ; st0 = 1; st1 = sqrt(sum)
    fxch
    fdivp           
    fild dword [dos55_32]
    fmulp
    fist dword aux
    emms
    mov eax, aux

    mov [edi], al
%endmacro


%define iteraciones_centro_fila (SCREEN_W*3 - 3)/16
%define bytes_fin_fila (SCREEN_W*3 - 3) % 16
%define aux [ebp - 4]
negative:
    entrada_funcion 4

    mov edi, [screen_pixeles]

    ; PROCESAR PRIMER PIXEL
    procesar_byte primero,arriba
    inc edi
    procesar_byte primero,arriba
    inc edi
    procesar_byte primero,arriba
    inc edi
    ; FIN PROCESAR PRIMER PIXEL

    mov ecx, iteraciones_centro_fila
iterar_primera_fila:
    procesar_pixels primera_fila

    add edi, 16
    dec ecx
    jne iterar_primera_fila
    
    ; PROCESAR ULTIMOS BYTES PRIMERA FILA
    mov ecx, bytes_fin_fila - 3
procesar_ultimos_bytes_primera_fila:
    procesar_byte medio, arriba
    inc edi
    dec ecx
    jne procesar_ultimos_bytes_primera_fila

    procesar_byte ultimo, arriba
    inc edi
    procesar_byte ultimo, arriba
    inc edi
    procesar_byte ultimo, arriba
    inc edi
    ; FIN PROCESAR ULTIMOS BYTES PRIMERA FILA

    ; ebx es el numero de filas a recorrer
    mov ebx, SCREEN_H - 2

recorrer_nueva_fila:

    ; PROCESAR PRIMER PIXEL
    procesar_byte primero,medio
    inc edi
    procesar_byte primero,medio
    inc edi
    procesar_byte primero,medio
    inc edi
    ; FIN PROCESAR PRIMER PIXEL


    mov ecx, iteraciones_centro_fila
seguir_recorriendo_fila:

    procesar_pixels centro

    add edi, 16

    dec ecx
    jne seguir_recorriendo_fila


    mov ecx, bytes_fin_fila - 3
procesar_bytes_fin_fila:

    procesar_byte medio, medio

    inc edi
    dec ecx
    jne procesar_bytes_fin_fila

    procesar_byte ultimo, medio
    inc edi
    procesar_byte ultimo, medio
    inc edi
    procesar_byte ultimo, medio
    inc edi

    dec ebx
    cmp ebx, 0
    jne recorrer_nueva_fila

    ; PROCESAR PRIMER PIXEL ULTIMA FILA
    procesar_byte primero,abajo
    inc edi
    procesar_byte primero,abajo
    inc edi
    procesar_byte primero,abajo
    inc edi
    ; FIN PROCESAR PRIMER PIXEL ULTIMA FILA

    mov ecx, iteraciones_centro_fila
iterar_ultima_fila:
    procesar_pixels ultima_fila

    add edi, 16
    dec ecx
    jne iterar_ultima_fila

    ; PROCESAR ULTIMOS BYTES ULTIMA FILA
    mov ecx, bytes_fin_fila - 3
procesar_ultimos_bytes_ultima_fila:
    procesar_byte medio, abajo
    inc edi
    dec ecx
    jne procesar_ultimos_bytes_ultima_fila

    procesar_byte ultimo, abajo
    inc edi
    procesar_byte ultimo, abajo
    inc edi
    procesar_byte ultimo, abajo
    inc edi
    ; FIN PROCESAR ULTIMOS BYTES ULTIMA FILA

    salida_funcion 4

