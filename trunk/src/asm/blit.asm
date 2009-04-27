;void blit(Uint8 *sprite, Uint32 ancho, Uint32 alto, Uint x, Uint y, Color color-off)

%include 'asm/macros_globales.inc'
%include 'asm/macros_pixels.inc'
	
%define SCREEN_W 800
%define SCREEN_H 400

%define ptrSprite       [ebp+8]
%define anchoSprite     [ebp+12]
%define altoSprite      [ebp+16]
%define coord_x         [ebp+20]
%define coord_y         [ebp+24]
%define color_off       [ebp+28]

%define ancho_screen_bytes [ebp-4]
%define ancho_sprite_bytes [ebp-8]
%define basura_sprite [ebp-12]
%define final	[ebp-16]
    
extern screen_pixeles

global blit

blit:
entrada_funcion 16
     
completo:
  		
    mov edi, ptrSprite					;edi apunta todo el tiempo a la posicion dentro de sprite
    
    ;esi <-- coord_y*(3*SCREEN_W + basura) + coord_x*3 + screen_pixeles
    
 		calcular_pixels ebx, anchoSprite
		calcular_basura edx,ebx
		mov basura_sprite,edx
		mov ancho_sprite_bytes,ebx
    
    calcular_pixels edx, SCREEN_W						;cargamos el ancho de la pantalla en edx y lo multiplicamos por 3
		calcular_basura ebx,edx 								;calculo la basura en ebx, desde edx
    add edx, ebx														;sumo el valor de la basura a edx
		mov ancho_screen_bytes,edx
		
    mov esi, [screen_pixeles]			;cargo el puntero a pantalla en esi    
		calcular_pixels ecx, coord_x	;cargamos la coor x en edx y lo multiplicamos por 3
    add esi, ecx									;le addiciono el valor de la coord_x a screen_pixeles
    mov eax, coord_y							;cargo la coord y en eax 
						
    mul edx												; (pierdo edx)
    add esi, eax									;eax posee la cantidad de bytes q hay q sumarle al puntero a screen
    
    mov edx, ancho_screen_bytes
    mov eax, altoSprite
    mul edx												;guardo en ecx la cantidad de bytes q usa el sprite							
    add eax, esi									;sumo el punto (0,0)
    mov final, eax
    
;edi apunta todo el tiempo a la posicion dentro de la pantalla
;las coordenadas (x, y) (x+p, y) (x, y+q) (x+p, y+q)
nueva_fila:				 								
  mov ecx, anchoSprite
while:
	;edi es el puntero al byte actual del sprite
	;reviso q el primer byte (red) sea igual
	mov bl, [edi] 		
	mov al, color_off	
	cmp al, bl
	jne no_cambio_color	
	
	;reviso q los 2 ultimos bytes (green-blue) sean iguales
	mov bx, [edi + 1]
	mov eax, color_off
	ror eax, 8											;realizo un desplazamiento para q los bytes green-blue queden en ax
	cmp ax, bx
	jne no_cambio_color

	;cambio el color_off por el fondo
	mov bl, [esi] 		;esi es el puntero al byte actual del screen
	mov [edi], bl
	
	mov bx, [esi + 1] 		
	mov [edi + 1], bx
	
no_cambio_color:	 
	add edi, 03h
	add esi, 03h
	loopne while
	
	add edi, basura_sprite
	sub esi, ancho_sprite_bytes
	add esi, ancho_screen_bytes	; edx queda apuntando al principio de la siguiente fila
	
	cmp esi, final
	je finBlit
	
	jmp nueva_fila
 
finBlit:
  
salida_funcion 16

