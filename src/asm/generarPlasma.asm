%include "asm/macros_globales.asm"

extern screen_pixeles
extern colores
extern g_ver0
extern g_ver1
extern g_hor0
extern g_hor1

%macro color_de_fondo 7

    mov %5, SCREEN_W*3
    ; tener en cuenta que esto toca edx
    mul %2

    mov %6, %1
    shl %6, 1

    mov %7, [screen_pixeles]
    
    add %7, %6
    add %7, %1

    mov dword [%7 + %5 + %3], %4

%endmacro

global generarPlasma

%define i esi
%define j ebx
%define rgb [ebp + 8]
generarPlasma:
    entrada_funcion 0

    xor i, i
loop_i:
    inc i

    xor j, j
loop_j:
    inc j


; cosas
    lea ecx, [j + j*4]
    add cx, [g_ver0]

    and ecx, 0x000001FF
    
    mov ecx, [colores + ecx*4]

    lea eax, [j + j*2]
    add ax, [g_ver1]

    and eax, 0x000001FF

    add ecx, [colores + eax*4]

    lea eax, [i + 2*i]
    add ax, [g_hor0]

    and eax, 0x000001FF

    add ecx, [colores + eax*4]

    mov eax, i
    add ax, [g_hor1]

    and eax, 0x000001FF

    add ecx, [colores + eax*4]

    ; es este shift?
    shr ecx, 4
    add ecx, 128                ; ecx es index

    mov eax, SCREEN_W*3
    ; tener en cuenta que esto toca edx
    mul j

    mov edi, [screen_pixeles]
    mov edx, i
    shl edx, 1
    add edi, edx
    add edi, i
    mov eax, [edi + eax]
    and eax, 0x00111111
    mov edi, rgb
    and edi, 0x00111111
    cmp eax, edi
    jne ir_a_seguir
    jmp no_ir_a_seguir

ir_a_seguir:
    jmp seguir

    ; aca viene el switch
no_ir_a_seguir:

    ;push ebp        ; "despejo" ebp
case_1:
    cmp ecx, 64
    jge case_2
    
    shl ecx, 2
    mov edi, 255
    sub edi, ecx
    dec edi

    color_de_fondo i,j,0,edi,eax,edx,ecx

    color_de_fondo i,j,1,ecx,eax,edx,ecx

    color_de_fondo i,j,2,0,eax,edx,ecx
    

    jmp salir
case_2:
    cmp ecx, 128
    jge case_3

    shl ecx, 2
    inc ecx
    color_de_fondo i,j,0,ecx,eax,edx,ecx
    color_de_fondo i,j,1,255,eax,edx,ecx
    color_de_fondo i,j,2,0,eax,edx,ecx

    jmp salir
case_3:
    cmp ecx, 192
    jge case_4

    shl ecx, 2
    mov edi, 255
    sub edi, ecx
    dec edi


    color_de_fondo i,j,0,edi,eax,edx,ecx
    color_de_fondo i,j,1,edi,eax,edx,ecx
    color_de_fondo i,j,2,0,eax,edx,ecx

;
    jmp salir
case_4:
    cmp ecx, 256
    jge case_5

    shl ecx, 2
    inc ecx
    color_de_fondo i,j,0,ecx,eax,edx,ecx
    color_de_fondo i,j,1,0,eax,edx,ecx
    color_de_fondo i,j,2,0,eax,edx,ecx
;
    jmp salir
case_5:
;

    color_de_fondo i,j,0,0,eax,edx,ecx
    color_de_fondo i,j,1,0,eax,edx,ecx
    color_de_fondo i,j,2,0,eax,edx,ecx

salir:
    

seguir:

    cmp j, SCREEN_H
    jle loop_j

    cmp i, SCREEN_W
    jle loop_i

    ;pop ebp

    add word [g_ver0], 9
    add word [g_hor0], 8

    salida_funcion 0
