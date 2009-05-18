;void recortar(Uint8* sprite, Uint32 instancia, Uint32 ancho_instancia, Uint32 ancho_sprite, Uint32 alto_sprite, Uint8* res, bool orientacion);


section .data

mask: dq 00000000000000FFh, 000000000000000h
maskn: dq 0xFFFFFFFFFFFFFF00, 0xFFFFFFFFFFFFFFFF
todos: dq 0xFFFFFFFFFFFFFFFF, 0xFFFFFFFFFFFFFFFF
shuff_ult: dq 06_0B_0A_09_1E_1D_1C_0Fh, 02_01_00_05_04_03_08_07h
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
%define linea_final [ebp-12]
%define cant_fila [ebp-16]
%define final [ebp-20]
%define offset_comienzo [ebp-24]

global recortar

recortar:

entrada_funcion 24

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

    mov eax, ecx                         ;tengo en ebx el ancho de la instancia en pixeles (sin la basura)
    mov ebx, 15
    div ebx                              ;15 bytes (5 pixels)
    cmp edx, 0                           ;cociente en eax y resto en edx
    je es_multiplo
    inc eax
es_multiplo:
    neg edx
    add edx, 16
	mov ecx, edx ; ecx = ultimos_bytes 

    mov cant_fila, eax
	dec eax
    mov ebx, 15
    mul ebx
	sub eax, ecx
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
	movdqu xmm3, [mask]						;guardo en xmm3 el la mascara negada
	movdqu xmm4, [maskn]					;guardo en xmm4 el la mascara negada
	
    mov eax, -15							;guardar en eax, el sentido en que se mueve esi
	
	neg dword orientacion					;si es izq tengo 0, si es der ahora tengo -1 (FFFFFFFFh)

    cmp dword orientacion, 0	
	je seguir

    neg eax
	movdqu xmm1, [shuff_no]				;cuando voy hacia la derecha, dejo como estan los bytes q leo del esi
	movdqu xmm2, [shuff_no]
	movdqu xmm3, [todos]					
	pxor xmm4, xmm4
seguir:  
    mov ecx, cant_fila                 ;ecx funciona de contador, indica por q pixel de la fila se encuenta el bucle
	dec ecx							   ;decremento ecx (queda a uno menos de la cantidad que deberia recorrer)
	mov ebx, linea_final
    sub ebx,esi						   ;hago la resta (me interesa si el resultado es cero, i.e. son iguales)
	and ebx, orientacion			   ;si la orientacion es hacia la izq anulo toda la operacion
	add ebx,-1						   ;si ebx es cualquier valor excepto cero, obtengo que CF = 1
   	adc ecx, 0						   ;corrigo ecx, en todos los casos (hacia la derecha), menos para la linea final

    mov edx, esi                             ;guardar en edx, la pos al principio de la iteracion
    
	mov ebx, orientacion
	not ebx
	and ebx, offset_comienzo    ;si estoy yendo hacia la izq, me posiciono en los ultimos 16 bytes
	add esi, ebx                ;si hay q espejar, ir hasta el ultimo elemento de la fila
	
	mov ebx, edi                             ;guardar en ebx, la pos al principio de la iteracion

ciclo:
    movdqu xmm0, [esi]
	pshufb xmm0, xmm1
    movdqu [edi], xmm0

    add edi, 15                              ;anvanzo un pixel en el buffer destino
    add esi, eax                             ;anvanzo o retrocedo un pixel en el sprite origen
    loopne ciclo                             ;cuando el contador se hace 0 salir del bucle
finalizacion:

	mov edi, ebx
	mov esi, edx
	add edi, offset_comienzo				
	
	movdqu xmm5, [esi]						 ;acomodar el ultimo elem para el caso hacia la izq
	movdqu xmm6, [edi]
	
	pshufb xmm5, xmm2
	pand xmm5, xmm4
	pand xmm6, xmm3
	
	por xmm5, xmm6
	movdqu [edi], xmm5						 ;cuando se recorre hacia la derecha esto no tiene efecto alguno
reconf_vars:
    mov edi, ebx
    add edi, ancho_total_instancia
    mov esi, edx                             ;recupero el valor al principio del iteracion
    add esi, ancho_sprite_bytes              ;y sumo para pasar a la siguiente fila
    cmp esi, final                           ;si se llego al final del sprite, terminar
	jl seguir
ultimo_chunk:
	cmp dword orientacion, 0
	je salir
	sub edi, ancho_total_instancia
	add edi, offset_comienzo
	
	sub esi, ancho_sprite_bytes
	add esi, offset_comienzo
    movdqu xmm0, [esi]
    movdqu [edi], xmm0
salir:
    salida_funcion 24

