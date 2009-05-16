%include "./asm/macros_globales.inc"

extern screen_pixeles

; lleva registro %1 al multiplo de 4 mayor mas cercano, usando %2 como
; registro auxiliar
%macro multiplo_de_4 2
%%chequear:
    mov %2, %1
    and %2, 0x00000003
    jz %%salir

    inc %1
    jmp %%chequear
%%salir:
%endmacro

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
    mov ecx, [screen_pixeles]      ; ecx es la base en la pantalla

    mov esi, edx 
    shl edx, 1
    add edx, esi        ; multiplicacion por 3

    add edx, fondo      ; edx es la base en el fondo

    mov esi, ebx
    shl ebx, 1
    add ebx, esi        ; multipliacion por 3
    multiplo_de_4 ebx,esi

    xor esi, esi        ; esi es la fila actual

    push ebp
    mov ebp, SCREEN_W*SCREEN_H*3
    add ebp, ecx

recorrer_y:
    xor edi, edi        ; edi es el offset (del fondo y la pantalla)

recorrer_x:
    mov eax, [edx + edi]
    mov [ecx + edi], eax

    mov eax, [edx + edi + 1]
    mov [ecx + edi + 1], eax

    mov eax, [edx + edi + 2]
    mov [ecx + edi + 2], eax


    add edi, 3
    cmp edi, SCREEN_W*3 - 3
    jl recorrer_x           ; ver si hay que pasar por x = SCREEN_W
    
    add edx, ebx            ; ebx era fondo_w*3 llevado a multiplo de 4

    mov esi, SCREEN_W*3

    add ecx, esi

    cmp ecx, ebp
    jl recorrer_y       ; ver si hay que pasar por y = SCREEN_H

    pop ebp

    salida_funcion 0
