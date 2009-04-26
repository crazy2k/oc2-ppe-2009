;void recortar(Uint8* sprite, Uint32 instancia, Uint32 ancho_instancia, Uint32 ancho_sprite, Uint32 alto_sprite, Uint8* res, bool orientacion);

%include 'asm/macros_globales.inc'

%define ptrSprite [ebp+8]
%define instancia [ebp+12]
%define ancho_instancia [ebp+16]
%define ancho_sprite [ebp+20]
%define alto_sprite [ebp+24]
%define ptrResultado [ebp+28]
%define orientacion [ebp+32]

%define ancho_instancia_bytes [ebp-4]
%define basura_instancia [ebp-8]
%define final [ebp-12]

global recortar

%macro calcular_pixels 2   ; registro y pos de memoria
		mov %1, %2						;cargamos la coor x en %1 y lo multiplicamos por 3
    shl %1, 1
    add %1, %2
%endmacro

%macro calcular_basura 2   ; registro y pos de memoria
    mov %1, %2 														
    and %1, 3h				         						;la basura del fondo bmp
    neg %1  
    add %1, 4h                 						;sumo 4 porq recién negamos ebx              
%endmacro

recortar:

entrada_funcion 12

	mov esi, ptrSprite
	mov edi, ptrResultado
	calcular_pixels ebx,ancho_instancia
	calcular_basura eax, ecx
  mov basura_instancia,eax										;basura para la instancia
  
	mov eax, instancia
	mul ebx                                  ;tengo la cant de bytes hasta la primera instancia
	add esi, eax                             ;en esi tengo el comienzo de la instancia dentro del sprite
	
	calcular_pixels ecx, ancho_sprite				 ;cantidada de pixeles q ocupa el sprite
  calcular_basura ebx,ecx  
  add ecx, ebx
  mov ancho_instancia_bytes, ecx					;ancho del sprite en pixeles

  mov eax, alto_sprite
  mul ecx										 ;esta en ex
  add eax,esi
  mov final, eax             ;calculo el final de la instancia

seguir:  
  mov ecx, ancho_instancia
      
ciclo:              ;voy copiando los bytes de cada fila de la instancia y dejandolos en *res
	mov bl, [esi] 		;edi es el puntero al byte actual de la instancia
	mov [edi], bl
	
	mov bx, [esi + 1] 		
	mov [edi + 1], bx

	add edi, 03h	
;	cmp orientacion,0
;	jne restar	
	add esi, 03h
;	jmp fin_ciclo
;restar:
;	sub esi, 03h

fin_ciclo:
	loopne ciclo
	
	calcular_pixels ebx, ancho_instancia
	add edi, basura_instancia
;	cmp orientacion,0
;	jne no_restar	
	sub esi, ebx
;no_restar:
	add esi, ancho_instancia_bytes
	cmp esi, final
	jne seguir
	
salida_funcion 12

