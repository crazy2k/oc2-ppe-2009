;void blit(Uint8 *sprite, Uint32 ancho, Uint32 alto, Uint x, Uint y, Color color-off)

%include 'asm/macros_globales.inc'
%include 'asm/macros_pixels.inc'

mask_repeat_3bytes: dq 0x0100020100020100, 0x0002010002010002
mask_repeat_first_byte: dq 0x0202010101000000, 0x1004040403030302

%define ptrSprite       [ebp+8]
%define anchoSprite     [ebp+12]
%define altoSprite      [ebp+16]
%define coord_x         [ebp+20]
%define coord_y         [ebp+24]
%define color_off       [ebp+28]

%define ancho_screen_bytes [ebp-4]
%define ancho_sprite_bytes [ebp-8]
%define basura_sprite [ebp-12]
%define final  [ebp-16]
    
extern screen_pixeles

global blit

blit:
entrada_funcion 16
     
completo:
      
    mov edi, ptrSprite                      ;edi apunta todo el tiempo a la posicion dentro de sprite
    
    ;esi <-- coord_y*(3*SCREEN_W + basura) + coord_x*3 + screen_pixeles
    
    calcular_pixels ebx,anchoSprite
    calcular_basura edx,ebx
    mov basura_sprite,edx
    mov ancho_sprite_bytes,ebx
    
    mov edx, SCREEN_W*3           ;cargamos el ancho de la pantalla en edx y lo multiplicamos por 3
    ;calcular_basura ebx,edx                 ;calculo la basura en ebx, desde edx
    ;add edx, ebx                            ;sumo el valor de la basura a edx
    mov ancho_screen_bytes,edx
    
    mov esi, [screen_pixeles]      ;cargo el puntero a pantalla en esi    
    calcular_pixels ecx, coord_x  ;cargamos la coor x en edx y lo multiplicamos por 3
    add esi, ecx                  ;le addiciono el valor de la coord_x a screen_pixeles
    mov eax, coord_y              ;cargo la coord y en eax 
            
    mul edx                        ; (pierdo edx)
    add esi, eax                  ;eax posee la cantidad de bytes q hay q sumarle al puntero a screen
    
    mov edx, ancho_screen_bytes
    mov eax, altoSprite
    mul edx                        ;guardo en ecx la cantidad de bytes q usa el sprite              
    add eax, esi                  ;sumo el punto (0,0)
    mov final, eax
    
;edi apunta todo el tiempo a la posicion dentro de la pantalla
;las coordenadas (x, y) (x+p, y) (x, y+q) (x+p, y+q)
nueva_fila:                         
  mov ecx, anchoSprite
while:

    movdqu xmm0, [edi]          ; xmm0 = [X|B|G|R|B|G|R|B|G|R|B|G|R|B|G|R]
                                ; (de la instancia)
    movdqu xmm2, xmm0

    pxor xmm1, xmm1
    mov eax, color_off
    and eax, 0x00FFFFFF
    movd xmm1, eax              ; xmm1 = [0|0|0|0|0|0|0|0|0|0|0|0|0|B|G|R]
                                ; (del color-off)

    pshufb xmm1, mask_repeat_3bytes 
                                ; xmm1 = [X|B|G|R|B|G|R|B|G|R|B|G|R|B|G|R]
                                ; (color-off replicado)

    pcmpeqb xmm0, xmm1          ; xmm0 = [X|F/0|                 ... |F/0]

    movdqu xmm3, xmm0
    movdqu xmm4, xmm0

    psrldq xmm3, 1
    psrldq xmm4, 2

    pand xmm0, xmm3             ; comparo los dos bytes menos significativos
    pand xmm0, xmm4             ; comparo los 3 bytes menos significativos

    pshufb xmm0, mask_repeat_first_byte

    ; en xmm2 tengo los bytes de la instancia
    movdqu xmm3, [esi]
    ; en xmm3 tengo los bytes de la pantalla
    
    pand xmm3, xmm0

    pandn xmm0, xmm0            ; xmm0 = not(xmm0)
    pand xmm2, xmm0

    por xmm2, xmm3

    movdqu [edi], xmm2

    add edi, 15
    add esi, 15
    loopne while

    add edi, basura_sprite
    sub esi, ancho_sprite_bytes
    add esi, ancho_screen_bytes  ; edx queda apuntando al principio de la siguiente fila

    cmp esi, final
    je finBlit

    jmp nueva_fila

finBlit:
  
salida_funcion 16

