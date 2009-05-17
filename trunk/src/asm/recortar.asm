;void recortar(Uint8* sprite, Uint32 instancia, Uint32 ancho_instancia, Uint32 ancho_sprite, Uint32 alto_sprite, Uint8* res, bool orientacion);


section .data

mask: dq 0000000000000000h, 8000000000000000h 
shuff_ult: dq 06_0B_0A_09_0E_0D_0C_0Fh, 02_01_00_05_04_03_08_07h
shuff_prs: dq 08_07_0C_0B_0A_0F_0E_0Dh, 00_03_02_01_06_05_04_09h
shuff_no: dq 07_06_05_04_03_02_01_00h, 0F_0E_0D_0C_0B_0A_09_08h

section .text

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
%define dist_utl_elem [ebp-12]
%define linea_final [ebp-16]
%define cant_fila [ebp-20]
%define ultimos_bytes [ebp-24]
%define final [ebp-28]
%define offset_comienzo [ebp-32]

global recortar

recortar:

entrada_funcion 32

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
    neg edx
    add edx, 16
    mov ultimos_bytes, edx

    dec eax
	mov cant_fila, eax
    mov ebx, 15
    mul ebx
    mov dist_utl_elem, eax
	sub eax, ultimos_bytes 
	mov offset_comienzo, eax

    mov eax, alto_sprite
    dec eax
    mov ecx, ancho_sprite_bytes
    mul ecx
    add eax, esi                              ;a esto le sumo el principio de la instancia para obtener donde termina esta
    mov linea_final, eax                           ;salvo el final de la instancia
    add eax, ancho_sprite_bytes
    mov final, eax

	movdqu xmm1, [shuff_prs]
	movdqu xmm2, [shuff_ult]
	movdqu xmm3, [mask]						;guardo en xmm4 el la mascara negada
	movdqu xmm4, xmm3
	pandn xmm4, xmm4						;guardo en xmm4 el la mascara negada

    mov eax, -15                            ;guardar en eax, el sentido en que se mueve esi
    cmp dword orientacion, 0
    je seguir
	mov ecx, cant_fila
	inc ecx
	mov cant_fila,ecx
    mov dword offset_comienzo, 0                    ;si se mueve hacia la derecha:
    neg eax
	movdqu xmm1, [shuff_no]
seguir:  
    mov ecx, cant_fila                 ;ecx funciona de contador, indica por q pixel de la fila se encuenta el bucle
    cmp esi, linea_final
    jl no_es_linea_final
    dec ecx
no_es_linea_final:
    mov edx, esi                             ;guardar en edx, la pos al principio de la iteracion
    mov ebx, edi                             ;guardar en ebx, la pos al principio de la iteracion
    add esi, offset_comienzo                       ;si hay q espejar, ir hasta el ultimo elemento de la fila
ciclo:

    movdqu xmm0, [esi]
	pshufb xmm0, xmm1
    movdqu [edi], xmm0

    add edi, 15                             ;anvanzo un pixel en el buffer destino
    add esi, eax                             ;anvanzo o retrocedo un pixel en el sprite origen
    loopne ciclo                             ;cuando el contador se hace 0 salir del bucle
finalizacion:
	cmp dword orientacion, 0
	je reconf_vars
	
reconf_vars:
    mov edi, ebx
    add edi, ancho_total_instancia
    mov esi, edx                             ;recupero el valor al principio del iteracion
    add esi, ancho_sprite_bytes              ;y sumo para pasar a la siguiente fila
    cmp esi, final                           ;si se llego al final del sprite, terminar
	jl seguir
ultimo_chunk:
    sub esi, ultimos_bytes
	sub esi, 15
	;sub esi, 15
	sub edi, 15
    sub edi, ultimos_bytes
    movdqu xmm0, [esi]
    movdqu [edi], xmm0

    salida_funcion 32

