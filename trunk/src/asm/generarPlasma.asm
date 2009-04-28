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
%macro color_de_fondo_old 2

    load_screenw_pixels

    ; uso edx porque total ya lo arruine con el mul...
    lea edx, [j + j * 2] ; edx = j + j*2 = j*3
    add edx, eax        ; edx = j*3 + i*SCREEN_W*3

    mov eax, [screen_pixeles]
    
    mov byte [eax + edx +%1], %2

%endmacro

%macro color_de_fondo 3
    mov byte [%1 + %2], %3
%endmacro

%macro load_screenw_pixels 0
    cmp dword res_mult, mult_invalid
    je %%calcular
    mov eax, res_mult
    jmp %%mult_salida
%%calcular:
    mov eax, SCREEN_W*3
    ; tener en cuenta que esto toca edx
    mul i                               ; eax = j*SCREEN_W*3
    mov res_mult, eax                   ; cacheo el resultado de mult
%%mult_salida:
%endmacro

%define mult_invalid 0xFFFFFFFF
    
global generarPlasma

%define i esi
%define j edi

%define rgb [ebp + 8]
%define res_mult [ebp - 4]
generarPlasma:
    entrada_funcion 4

    mov dword res_mult, mult_invalid    ;resetear valor de mult
    xor i, i
loop_i:

    xor j, j
loop_j:

    lea ecx, [j + j*4]

    xor edx, edx
    mov dx, [g_ver0] 
    add ecx, edx

    and ecx, 0x000001FF
    
    mov ecx, [colores + ecx*4]

    lea eax, [j + j*2]

    xor edx, edx
    mov dx, [g_ver1]
    add eax, edx

    and eax, 0x000001FF

    add ecx, [colores + eax*4]

    lea eax, [i + 2*i]

    xor edx, edx
    mov dx, [g_hor0]
    add eax, edx

    and eax, 0x000001FF

    add ecx, [colores + eax*4]

    mov eax, i
    xor edx, edx
    mov dx, [g_hor1]
    add eax, edx

    and eax, 0x000001FF

    add ecx, [colores + eax*4]

    sar ecx, 4
    add ecx, 128                        ; ecx es index
    and ecx, 0xFF

    load_screenw_pixels

    mov ebx, [screen_pixeles]
    lea edx, [ j + j * 2 ]
    add ebx, edx                          ; ebx = [screen_pixeles] + 3*i

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

    load_screenw_pixels ;cargo en eax, el desplazamiento vertical (en bytes)
    lea edx, [j + j * 2] ; edx = j + j*2 = j*3
    add eax, edx        ; eax = j*3 + i*SCREEN_W*3
    add eax, [screen_pixeles]   ;queda todo el offset completo en eax

case_1:
    cmp cl, 64
    jae case_2                          ; fallaba por q jge es signed
    
    shl cl, 2                           ; cl = index << 2
    mov bl, 255
    sub bl, cl
    dec bl                              ; bl = 255 - ((index << 2) + 1)

    color_de_fondo eax,0,bl
    color_de_fondo eax,1,cl
    color_de_fondo eax,2,0
    
    jmp seguir

case_2:
    cmp cl, 128
    jae case_3

    shl cl, 2
    inc cl                              ; cl = (index << 2) + 1

    color_de_fondo eax,0,cl
    color_de_fondo eax,1,255
    color_de_fondo eax,2,0

    jmp seguir

case_3:
    cmp cl, 192
    jae case_4

    shl cl, 2
    mov bl, 255
    sub bl, cl
    dec bl                             ; bl = 255 - ((index << 2) + 1)

    color_de_fondo eax,0,bl
    color_de_fondo eax,1,bl
    color_de_fondo eax,2,0

    jmp seguir

case_4:
    cmp cx, 256                        ;256 no entra en 8 bits (por eso us cx)
    jae case_5

    shl cl, 2
    inc cl                             ; cl = (index << 2) + 1

    color_de_fondo eax,0,cl
    color_de_fondo eax,1,0
    color_de_fondo eax,2,0
    
    jmp seguir

case_5:

    color_de_fondo eax,0,0
    color_de_fondo eax,1,0
    color_de_fondo eax,2,0


seguir:
    
    inc j
    cmp j, SCREEN_W
    jl loop_j
    
    mov dword res_mult, mult_invalid    ;resetear valor de mult    

    inc i
    cmp i, SCREEN_H
    jl loop_i

    add word [g_ver0], 9
    add word [g_hor0], 8

    salida_funcion 4
