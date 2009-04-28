%include "asm/macros_globales.inc"

extern screen_pixeles
extern colores
extern g_ver0
extern g_ver1
extern g_hor0
extern g_hor1

; color_de_fondo escribe en el valor %1 del pixel (i, j) de la pantalla
; el numero %2. %1 puede ser: 0 (R), 1 (G) o 2 (B) (debe ser inmediato). %2
; puede ser un registro o un inmediato de 8 bits. color_de_fondo utiliza
; internamente eax y edx para realizar calculos.
%macro color_de_fondo 2

    mov eax, SCREEN_W*3
    ; tener en cuenta que esto toca eax y edx
    mul j               ; eax = j*SCREEN_W*3

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

%define rgb [ebp + 8]
generarPlasma:
    entrada_funcion 0

    xor i, i
loop_i:

    xor j, j
loop_j:

    ;lea ecx, [i + i*4]
    lea ecx, [j + j*4]

    xor edx, edx
    mov dx, [g_ver0] 
    add ecx, edx

    and ecx, 0x000001FF
    
    mov ecx, [colores + ecx*4]

    ;lea eax, [i + i*2]
    lea eax, [j + j*2]

    xor edx, edx
    mov dx, [g_ver1]
    add eax, edx

    and eax, 0x000001FF

    add ecx, [colores + eax*4]

    ;lea eax, [j + 2*j]
    lea eax, [i + 2*i]

    xor edx, edx
    mov dx, [g_hor0]
    add eax, edx

    and eax, 0x000001FF

    add ecx, [colores + eax*4]

    ;mov eax, j
    mov eax, i
    xor edx, edx
    mov dx, [g_hor1]
    add eax, edx

    and eax, 0x000001FF

    add ecx, [colores + eax*4]

    sar ecx, 4
    add ecx, 128                        ; ecx es index
    and ecx, 0xFF

    mov eax, SCREEN_W*3
    ; tener en cuenta que esto toca edx
    mul j                               ; eax = j*SCREEN_W*3

    mov ebx, [screen_pixeles]
    mov edx, i
    shl edx, 1
    add ebx, edx
    add ebx, i                          ; ebx = [screen_pixeles] + 3*i

    mov dh, [ebx + eax + 2]
    shl edx, 8
    mov dx, [ebx + eax]
    mov eax, edx

    and eax, 0x00FFFFFF
    mov ebx, rgb
    and ebx, 0x00FFFFFF                 ; me quedo con los 3 bytes menos sign.
    cmp eax, ebx
    jne ir_a_seguir
    jmp entrar_al_switch

ir_a_seguir:
    jmp seguir

    ; aca viene el switch
entrar_al_switch:

case_1:
    cmp ecx, 64
    jge case_2
    
    shl cl, 2                           ; cl = index << 2
    mov bl, 255
    sub bl, cl
    dec bl                              ; bl = 255 - ((index << 2) + 1)

    color_de_fondo 0,bl
    color_de_fondo 1,cl
    color_de_fondo 2,0
    
    jmp seguir

case_2:
    cmp ecx, 128
    jge case_3

    shl cl, 2
    inc cl                              ; cl = (index << 2) + 1

    color_de_fondo 0,cl
    color_de_fondo 1,255
    color_de_fondo 2,0

    jmp seguir

case_3:
    cmp ecx, 192
    jge case_4

    shl cl, 2
    mov bl, 255
    sub bl, cl
    dec bl                             ; bl = 255 - ((index << 2) + 1)

    color_de_fondo 0,bl
    color_de_fondo 1,bl
    color_de_fondo 2,0

    jmp seguir

case_4:
    cmp ecx, 256
    jge case_5

    shl cl, 2
    inc cl                             ; cl = (index << 2) + 1

    color_de_fondo 0,cl
    color_de_fondo 1,0
    color_de_fondo 2,0
    
    jmp seguir

case_5:

    color_de_fondo 0,0
    color_de_fondo 1,0
    color_de_fondo 2,0


seguir:

    inc j
    cmp j, SCREEN_H
    jl loop_j

    inc i
    cmp i, SCREEN_W
    jl loop_i

    add word [g_ver0], 9
    add word [g_hor0], 8

    salida_funcion 0
