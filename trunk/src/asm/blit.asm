;void blit(Uint8 *sprite, Uint32 ancho, Uint32 alto, Uint x, Uint y, Color color-off)

%include 'asm/macros_globales.inc'
%include 'asm/macros_pixels.inc'

mask_repeat_3bytes: dq 0x0100020100020100, 0x1002010002010002
mask_repeat_first_byte: dq 0x06_06_03_03_03_00_00_00, 0x10_0C_0C_0C_09_09_09_06
mask_origen: dq 0xFFFFFFFFFFFFFFFF, 0x00FFFFFFFFFFFFFF
uno: dq 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF

%macro copiar 0
    movdqu xmm0, [edi]          ; xmm0 = [X|B|G|R|B|G|R|B|G|R|B|G|R|B|G|R]
                                ; (de la instancia)
    movdqu xmm2, xmm0

    pxor xmm1, xmm1
    mov eax, color_off
    and eax, 0x00FFFFFF
    movd xmm1, eax              ; xmm1 = [0|0|0|0|0|0|0|0|0|0|0|0|0|B|G|R]
                                ; (del color-off)

    pshufb xmm1, [mask_repeat_3bytes]
                                ; xmm1 = [X|B|G|R|B|G|R|B|G|R|B|G|R|B|G|R]
                                ; (color-off replicado)

    pcmpeqb xmm0, xmm1          ; xmm0 = [X|F/0|                 ... |F/0]

    movdqu xmm3, xmm0
    movdqu xmm4, xmm0

    psrldq xmm3, 1
    psrldq xmm4, 2

    pand xmm0, xmm3             ; comparo los dos bytes menos significativos
    pand xmm0, xmm4             ; comparo los 3 bytes menos significativos

    pshufb xmm0, [mask_repeat_first_byte]
    pand xmm0, [mask_origen]
    
    ; en xmm2 tengo los bytes de la instancia
    movdqu xmm3, [esi]
    ; en xmm3 tengo los bytes de la pantalla
    
    pand xmm3, xmm0

    pxor xmm0, xmm7            ; xmm0 = not(xmm0)
    pand xmm2, xmm0

    por xmm2, xmm3

    movdqu [edi], xmm2

%endmacro

%define ptrSprite       [ebp+8]
%define anchoSprite     [ebp+12]
%define altoSprite      [ebp+16]
%define coord_x         [ebp+20]
%define coord_y         [ebp+24]
%define color_off       [ebp+28]

%define ancho_screen_bytes [ebp-4]
%define ancho_sprite_bytes [ebp-8]
%define ancho_total_sprite [ebp-12]
%define final  [ebp-16]
%define cant_elem  [ebp-20]
%define linea_final  [ebp-24]
%define offset_final  [ebp-28]
    
extern screen_pixeles

global blit

blit:
entrada_funcion 28
     
completo:
      
    mov edi, ptrSprite                  ; edi = posicion actual dentro del sprite

    ; quiero:
    ;   esi = [screen_pixeles] + coord_y*(SCREEN_W*3) + en_bytes(coord_x)
    
    calcular_pixels ebx,anchoSprite
    calcular_basura edx,ebx

    mov ancho_sprite_bytes,ebx
    add ebx ,edx
    mov ancho_total_sprite, ebx
    
    mov edx, SCREEN_W*3             ; edx = SCREEN_W*3
    mov ancho_screen_bytes, edx
    
    mov esi, [screen_pixeles]       ; esi = [screen_pixeles]

    calcular_pixels ecx, coord_x    ; ecx = en_bytes(coord_x)
    add esi, ecx                    ; esi = [screen_pixeles] + en_bytes(coord_x)

    mov eax, coord_y                ; eax = coord_y
            
    mul edx                         ; eax = coord_y*SCREEN_W*3 (pierdo edx)
    add esi, eax                    ; esi tiene ahora la primera posicion en
                                    ; la pantalla correspondiente al sprite
    
    

    mov edx, ancho_screen_bytes
    ;dec edx
    mov eax, altoSprite
    dec eax
    mul edx
    add eax, esi
    mov linea_final, eax

    mov eax, ancho_total_sprite
    sub eax, 32
    mov offset_final, eax           ; final es el ultimo cacho de 128 bits
                                    ; para leer de la pantalla
    add eax, linea_final
    mov final, eax

    mov eax, ancho_sprite_bytes
    xor edx, edx
    mov ecx, 15
    div ecx
    cmp edx, 0
    je es_mult 
    inc eax
es_mult:    
    mov cant_elem , eax

    movdqu xmm7,[uno] 

nueva_fila:                         
    mov ecx, cant_elem
    mov ebx, edi
    mov edx, esi

    cmp edx, linea_final
    jb while
    dec ecx

while:

    copiar

    add edi, 15
    add esi, 15
    loopne while

    mov edi, ebx
    add edi, ancho_total_sprite  ; edx queda apuntando al principio de la siguiente fila
    mov esi, edx
    add esi, ancho_screen_bytes  ; edx queda apuntando al principio de la siguiente fila

    cmp esi, final
    jae finBlit

    jmp nueva_fila

finBlit:
    
    mov edi, ebx
    add edi, offset_final

    mov esi, edx
    add esi, offset_final
    
    ;movdqu xmm0, [esi]
    ;movdqu [edi], xmm0

    copiar
    add edi, 15
    add esi, 15

    copiar


salida_funcion 28

