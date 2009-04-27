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
%define basura_instancia [ebp-8]
%define ancho_instancia_bytes [ebp-12]
%define final [ebp-16]

global recortar

recortar:

entrada_funcion 12

	mov esi, ptrSprite
	mov edi, ptrResultado
	calcular_pixels ebx,ancho_instancia
	mov ancho_instancia_bytes, ebx					;ancho de la instancia sobre el sprite en pixeles (sin la basura)
	calcular_basura eax, ebx
  mov basura_instancia,eax								;basura para la instancia
  
	mov eax, instancia
	mul ebx                                 ;tengo la cant de bytes hasta la primera instancia
	add esi, eax                            ;en esi tengo el comienzo de la instancia dentro del sprite
	
	calcular_pixels ecx, ancho_sprite				;cantidada de pixeles q ocupa el sprite
  calcular_basura ebx,ecx  								;basura del sprite
  add ecx, ebx
  mov ancho_sprite_bytes, ecx							;ancho del sprite en pixeles (ecx)

  mov eax, alto_sprite										;cantida de filas que tiene el sprite (eax)
  mul ecx																  ;en eax, queda la cantidad de bytes q ocupa el sprite
  add eax,esi															;a esto le sumo el principio de la instancia para obtener donde termina esta
  mov final, eax             							;salvo el final de la instancia

seguir:  
  mov ecx, ancho_instancia								;ecx funciona de contador, indica por q pixel de la fila se encuenta el bucle
	cmp dword orientacion, 0
  jne ciclo									 
  add esi, ancho_instancia_bytes 					;si hay q espejar, ir hasta el ultimo elemento de la fila
  sub esi, 03h
ciclo:              ;voy copiando los bytes de cada fila de la instancia y dejandolos en *res
	mov bl, [esi] 		;edi es el puntero al byte actual de la instancia
	mov [edi], bl
	
	mov bx, [esi + 1] 		
	mov [edi + 1], bx

	add edi, 03h	
	
	cmp dword orientacion,0
	je restar	
	add esi, 03h
	jmp fin_ciclo
restar:
	sub esi, 03h

fin_ciclo:
	loopne ciclo
	
	add edi, basura_instancia
	
	cmp dword orientacion,0
	je no_restar
	sub esi, ancho_instancia_bytes
	jmp seguir2
no_restar:
	add esi, 3h
seguir2:
	
	add esi, ancho_sprite_bytes										;paso a la siguiente fila
	cmp esi, final																;si se llego al final del sprite, terminar
	jne seguir
	
salida_funcion 12

