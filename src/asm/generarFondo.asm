%include "macros_globales.asm"

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
    sub edx, SCREEN_W   ; edx = coordenada posta

seguir:
    xor ecx, ecx        ; ecx es la base en la pantalla
    ; edx es la base en el fondo (empieza siendo la coordenada posta)

recorrer_y:
    xor edi, edi        ; edi es el offset (del fondo y la pantalla)


recorrer_x:
    mov eax, [edx + edi]
    mov [ecx + edi], eax

    mov eax, [edx + edi + 1]
    mov [ecx + edi + 1], eax

    mov eax, [edx + edi + 2]
    mov [ecx + edi + 2], eax

; cosas


    add edi, 3
    cmp edi, SCREEN_W
    jl recorrer_x       ; ver si hay que pasar por x = SCREEN_W
    
    add edx, ebx        ; ebx era fondo_w
    add ecx, SCREEN_W
    cmp ecx, SCREEN_H*SCREEN_W
    jl recorrer_y       ; ver si hay que pasar por y = SCREEN_H

    salida_funcion 0