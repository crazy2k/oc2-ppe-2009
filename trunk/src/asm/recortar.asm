;void recortar(Uint8* sprite, Uint32 instancia, Uint32 ancho_instancia, Uint32 ancho_sprite, Uint32 alto_sprite, Uint8* res, bool orientacion);

%include 'asm/macros_globales.inc'
%include 'asm/macros_pixels.inc'

%define ptrSprite [ebp+8]
%define instancia [ebp+12]
%define ancho_instancia [ebp+16]
%define ancho_sprite [ebp+20]
%define alto_sprite [ebp+24]
%define ptrResultado [ebp+28]
%define orientacion [ebp+32]

%define ancho_sprite_bytes [ebp-4]
%define ancho_total_instancia [ebp-8]
%define defasaje [ebp-12]
%define linea_final [ebp-16]
%define cant_fila [ebp-20]
%define ultimos_bytes [ebp-24]
%define final [ebp-28]

global recortar

recortar:

entrada_funcion 28

    mov esi, ptrSprite
    mov edi, ptrResultado
    calcular_pixels ecx,ancho_instancia      ;ebx: ancho de la instancia sobre el sprite en pixeles (sin la basura)
    calcular_basura eax, ecx                 ;basura para la instancia
    add eax, ecx
    mov ancho_total_instancia, eax
    
    mov eax, instancia
    mul ecx                                  ;tengo en edx:eax la cant de bytes hasta la primera instancia
    add esi, eax                             ;en esi tengo el comienzo de la instancia dentro del sprite
  
    calcular_pixels eax, ancho_sprite        ;cantidad de pixeles q ocupa el sprite
    calcular_basura ebx,eax                  ;basura del sprite
    add eax, ebx
    mov ancho_sprite_bytes, eax              ;ancho del sprite en pixeles (ecx)

    mov eax, ecx                        ;tengo en ebx el ancho de la instancia en pixeles (sin la basura)
    mov ebx, 15
    div ebx                              ; 15 bytes (5 pixels)
    cmp edx, 0                           ;cociente en eax y resto en edx
    je es_multiplo
    inc eax
es_multiplo:
    mov cant_fila, eax
    neg edx
    add edx, 16
    mov ultimos_bytes, edx

    dec eax
    mov ebx, 15
    mul ebx
    mov defasaje, eax

    mov eax, alto_sprite
    dec eax
    mov ecx, ancho_sprite_bytes
    mul ecx
    add eax, esi                              ;a esto le sumo el principio de la instancia para obtener donde termina esta
    mov linea_final, eax                           ;salvo el final de la instancia
    add eax, defasaje
    mov final, eax

    mov eax, -15                            ;guardar en eax, el sentido en que se mueve esi
    cmp dword orientacion, 0
    ;je seguir
    mov dword defasaje, 0                    ;si se mueve hacia la derecha:
    neg eax 
seguir:  
    mov ecx, cant_fila                 ;ecx funciona de contador, indica por q pixel de la fila se encuenta el bucle
    cmp esi, linea_final
    jl no_es_linea_final
    dec ecx
no_es_linea_final:
    mov edx, esi                             ;guardar en edx, la pos al principio de la iteracion
    mov ebx, edi                             ;guardar en ebx, la pos al principio de la iteracion
    add esi, defasaje                        ;si hay q espejar, ir hasta el ultimo elemento de la fila
ciclo:

    movdqu xmm0, [esi]
    movdqu [edi], xmm0

    add edi, 15                             ;anvanzo un pixel en el buffer destino
    add esi, eax                             ;anvanzo o retrocedo un pixel en el sprite origen
    loopne ciclo                             ;cuando el contador se hace 0 salir del bucle
finalizacion:  
    cmp esi, final                           ;si se llego al final del sprite, terminar
    je ultimo_chunk
    mov edi, ebx
    add edi, ancho_total_instancia
    mov esi, edx                             ;recupero el valor al principio del iteracion
    add esi, ancho_sprite_bytes              ;y sumo para pasar a la siguiente fila
    jmp seguir
ultimo_chunk: 
    sub edi, ultimos_bytes
    sub esi, ultimos_bytes
    movdqu xmm0, [esi]
    movdqu [edi], xmm0

    salida_funcion 28

