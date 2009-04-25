%include "./asm/macros_globales.asm"

extern screen_pixeles

global generarFondo

section .text

%define fondo [ebp + 8]
%define fondo_w [ebp + 12]
%define fondo_h [ebp + 16]
%define coord [ebp + 20]
; void generarFondo (Uint8 *fondo, Uint32 fondo_w, Uint32 fondo_h, Uint32 screenAbsPos)

generarFondo:
    entrada_funcion 0

    mov eax, coord
    mov edx, eax        ; edx = coord
    add eax, SCREEN_W   ; eax = coord + SCREEN_W

    mov ebx, fondo_w    ; ebx = fondo_w
    cmp eax, ebx
    jle seguir

    mov edx, ebx
    sub edx, SCREEN_W   ; edx = "coordenada posta"

seguir:
    mov ecx, screen_pixeles
    mov ecx, [ecx]      ; ecx es la base en la pantalla

    mov esi, edx 
    shl edx, 1
    add edx, esi        ; multiplicacion por 3

    add edx, fondo      ; edx es la base en el fondo

    mov esi, ebx
    shl ebx, 1
    add ebx, esi        ; multipliacion por 3

    xor esi, esi        ; esi es la fila actual

recorrer_y:
    xor edi, edi        ; edi es el offset (del fondo y la pantalla)
    inc esi

recorrer_x:
    mov eax, [edx + edi]
    mov [ecx + edi], eax

    mov eax, [edx + edi + 1]
    mov [ecx + edi + 1], eax

    mov eax, [edx + edi + 2]
    mov [ecx + edi + 2], eax

; cosas


    add edi, 3
    cmp edi, SCREEN_W*3
    jl recorrer_x       ; ver si hay que pasar por x = SCREEN_W
    
    add edx, ebx        ; ebx era fondo_w*3
    add ecx, SCREEN_W*3

    cmp esi, SCREEN_H
    jl recorrer_y       ; ver si hay que pasar por y = SCREEN_H

    salida_funcion 0
