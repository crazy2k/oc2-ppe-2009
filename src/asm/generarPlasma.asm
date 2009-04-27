%include "asm/macros_globales.inc"

extern screen_pixeles
extern colores
extern g_ver0
extern g_ver1
extern g_hor0
extern g_hor1

; color_de_fondo escribe en el valor %1 del pixel (i, j) de la pantalla
; el numero %2. %1 puede ser: 0 (R), 1 (G) o 2 (B) (debe ser inmediato). %2
; puede ser un registro o un inmediato. color_de_fondo utiliza internamente
; eax y edx para realizar calculos, y tambien el registro auxiliar pasado
; en %3.
%macro color_de_fondo 3

    mov eax, SCREEN_W*3
    ; tener en cuenta que esto toca eax y edx
    mul j              ; eax = j*SCREEN_W*3

    ; uso edx porque total ya lo arruine con el mul...
    mov edx, i
    shl edx, 1
    add edx, i          ; edx = i*2 + i = i*3
    add edx, eax        ; edx = i*3 + j*SCREEN_W*3

    mov eax, [screen_pixeles]
    
    mov byte [eax + edx + %1], %2

%endmacro

global generarPlasma

%define i esi
%define j edi

; prometo ser un buen chico y nunca usar el stack, despues de pushear ebp :)
; por eso, defino las direcciones usando como referencia *esp despues de
; pushear ebp*
%define rgb [esp + 28]
%define rgb_local [esp + 16]
generarPlasma:
    entrada_funcion 4

    push ebp                ; libero el ebp; no voy a acceder a ninguna
                            ; direccion de memoria usandolo

    mov eax, rgb
    mov rgb_local, eax

    xor i, i
loop_i:


    xor j, j
loop_j:

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
    sar ecx, 4
    add ecx, 128                        ; cl es index

    mov eax, SCREEN_W*3
    ; tener en cuenta que esto toca edx
    mul j                               ; eax = j*SCREEN_W*3

    mov ebx, [screen_pixeles]
    mov edx, i
    shl edx, 1
    add ebx, edx
    add ebx, i                          ; ebx = [screen_pixeles] + 3*i
    mov eax, [ebx + eax]                ; en eax tengo el pixel y un byte

    and eax, 0x00FFFFFF
    mov ebx, rgb_local
    and ebx, 0x00FFFFFF                 ; me quedo con los 3 bytes menos sign.
    cmp eax, ebx
    jne ir_a_seguir
    jmp no_ir_a_seguir

ir_a_seguir:
    jmp seguir

    ; aca viene el switch
no_ir_a_seguir:

case_1:
    cmp ecx, 64
    jge case_2
    
    shl cl, 2                           ; cl = index << 2
    mov bl, 255
    sub bl, cl
    dec bl                              ; bl = 255 - ((index << 2) + 1)

    color_de_fondo 0,bl,ebp
    color_de_fondo 1,cl,ebp
    color_de_fondo 2,0,ebp
    
    jmp salir

case_2:
    cmp ecx, 128
    jge case_3

    shl cl, 2
    inc cl                              ; cl = (index << 2) + 1

    color_de_fondo 0,cl,ebp
    color_de_fondo 1,255,ebp
    color_de_fondo 2,0,ebp

    jmp salir

case_3:
    cmp ecx, 192
    jge case_4

    shl cl, 2
    mov bl, 255
    sub bl, cl
    dec bl                             ; bl = 255 - ((index << 2) + 1)

    color_de_fondo 0,bl,ebp
    color_de_fondo 1,bl,ebp
    color_de_fondo 2,0,ebp

    jmp salir

case_4:
    cmp ecx, 256
    jge case_5

    shl cl, 2
    inc cl                             ; cl = (index << 2) + 1

    color_de_fondo 0,cl,ebp
    color_de_fondo 1,0,ebp
    color_de_fondo 2,0,ebp
;
    jmp salir
case_5:
;

    color_de_fondo 0,0,ebp
    color_de_fondo 1,0,ebp
    color_de_fondo 2,0,ebp

salir:
    

seguir:

    inc j
    cmp j, SCREEN_H
    jle loop_j

    inc i
    cmp i, SCREEN_W
    jle loop_i

    pop ebp

    add word [g_ver0], 9
    add word [g_hor0], 8

    salida_funcion 4
