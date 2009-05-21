; void negative()

%include 'asm/macros_globales.inc'

extern screen_pixeles

global  negative

guardar_ultimo_byte: dq 0x0000000000000000,0xFF00000000000000
ceros: dq 0x0000000000000000, 0x0000000000000000
uno: dq 0x0000000000000001, 0x0000000000000000
dos55_replicado: dq 0x000000FF000000FF, 0x000000FF000000FF
reordenar_words_0: dq 0x808080800C080400, 0x8080808080808080
reordenar_words_1: dq 0x0C08040080808080, 0x8080808080808080
reordenar_words_4: dq 0x8080808080808080, 0x808080800C080400
reordenar_words_5: dq 0x8080808080808080, 0x8008040080808080

%define ultimo_byte [ebp - 16]
negative:
    entrada_funcion 16

    mov edi, [screen_pixeles]

    ; avanzo hasta el cuerpo del medio
    lea edi, [edi + SCREEN_W*3 + 3]     ; edi es el puntero al nodo central

    ; ebx es el numero de filas a recorrer
    mov ebx, SCREEN_H - 4

recorrer_nueva_fila:
    mov esi, edi                        ; salvo en esi el principio de la fila

    mov eax, edi
    lea eax, [eax + SCREEN_W*3 - 3 - 20]  ; eax es el final de la fila

seguir_recorriendo_fila:
    movdqu xmm0, [edi]
    pand xmm0, [guardar_ultimo_byte]
    movdqu ultimo_byte, xmm0

    movdqu xmm0, [edi - SCREEN_W*3]
    movdqu xmm1, [edi - 3]
    movdqu xmm2, [edi + 3]
    movdqu xmm3, [edi + SCREEN_W*3] ; xmmi = [X|BGR|BGR|BGR|BGR|BGR]
                                    ; (una posicion es un byte)

    movdqu xmm4, xmm0
    movdqu xmm5, xmm1
    movdqu xmm6, xmm2
    movdqu xmm7, xmm3       ; xmmi = [X|BGR|BGR|BGR|BGR|BGR]
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
    punpckhbw xmm7, [ceros] ; xmmi = [XX|(0B)(0G)(0R)|(0B)(0G)(0R)|(0B)]


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
    punpckhwd xmm5, [ceros] ; xmm5 = [XXXX|...  ] (los 32 bits mas sign.
                            ; no me sirven)

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

    movdqu xmm1, ultimo_byte
    por xmm0, xmm1

    movdqu [edi], xmm0

    add edi, 15

    cmp edi, eax
    jl seguir_recorriendo_fila

    mov edi, esi
    add edi, SCREEN_W*3

    dec ebx
    cmp ebx, 0
    jne recorrer_nueva_fila


    salida_funcion 16

