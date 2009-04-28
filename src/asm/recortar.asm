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
%define defasaje [ebp-12]
%define final [ebp-16]

global recortar

recortar:

entrada_funcion 12

  mov esi, ptrSprite
  mov edi, ptrResultado
  calcular_pixels ebx,ancho_instancia      ;ebx: ancho de la instancia sobre el sprite en pixeles (sin la basura)
  calcular_basura eax, ebx                 ;basura para la instancia
  mov basura_instancia,eax                
    
  mov eax, instancia
  mul ebx                                  ;tengo en edx:eax la cant de bytes hasta la primera instancia
  add esi, eax                             ;en esi tengo el comienzo de la instancia dentro del sprite
  
  sub ebx, 03h                             ;cantidad de bytes para avanzar del primer al ultimo pixel de una fila
  mov defasaje, ebx                        
  
  calcular_pixels ecx, ancho_sprite        ;cantidad de pixeles q ocupa el sprite
  calcular_basura ebx,ecx                  ;basura del sprite
  add ecx, ebx
  mov ancho_sprite_bytes, ecx              ;ancho del sprite en pixeles (ecx)

  mov eax, alto_sprite                     ;cantida de filas que tiene el sprite (eax)
  mul ecx                                  ;en eax, queda la cantidad de bytes q ocupa el sprite
  add eax,esi                              ;a esto le sumo el principio de la instancia para obtener donde termina esta
  mov final, eax                           ;salvo el final de la instancia

  mov eax, -03h                            ;guardar en eax, el sentido en que se mueve esi
  cmp dword orientacion, 0
  je seguir
  mov dword defasaje, 0                    ;si se mueve hacia la derecha:
  neg eax 
seguir:  
  mov ecx, ancho_instancia                 ;ecx funciona de contador, indica por q pixel de la fila se encuenta el bucle
  mov edx, esi                             ;guardar en edx, la pos al principio de la iteracion
  add esi, defasaje                        ;si hay q espejar, ir hasta el ultimo elemento de la fila
ciclo:                                    
  mov bl, [esi]                            ;voy copiando los bytes de cada fila de la instancia y dejandolos en *res
  mov [edi], bl                            ;edi es el puntero al byte actual de la instancia
  
  mov bx, [esi + 1]     
  mov [edi + 1], bx

  add edi, 03h                             ;anvanzo un pixel en el buffer destino
  add esi, eax                             ;anvanzo o retrocedo un pixel en el sprite origen
  loopne ciclo                             ;cuando el contador se hace 0 salir del bucle
finalizacion:  
  add edi, basura_instancia
  mov esi, edx                             ;recupero el valor al principio del iteracion
  add esi, ancho_sprite_bytes              ;y sumo para pasar a la siguiente fila
  cmp esi, final                           ;si se llego al final del sprite, terminar
  jne seguir
  
salida_funcion 12

