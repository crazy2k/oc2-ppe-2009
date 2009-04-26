;void blit(Uint8 *sprite, Uint32 ancho, Uint32 alto, Uint x, Uint y, Color color-off)

%include 'asm/macros_globales.asm'
	
%define SCREEN_W 800
%define SCREEN_H 400

%define ptrSprite       [ebp+8]
%define anchoSprite     [ebp+12]
%define altoSprite      [ebp+16]
%define coord_x         [ebp+20]
%define coord_y         [ebp+24]
%define color_off       [ebp+28]
%define final						[ebp+0]
%define ancho_screen_bytes [ebp-4]

%macro calcular_pixels 2   ; registro y pos de memoria
		mov %1, %2						;cargamos la coor x en edx y lo multiplicamos por 3
    shl %1, 1
    add %1, %2
%endmacro

%macro calcular_basura 2   ; registro y pos de memoria
    mov %1, %2 														
    and %1, 3h				         						;la basura del fondo bmp
    neg %1  
    add %1, 4h                 						;sumo 4 porq recién negamos ebx              
%endmacro
    
extern screen_pixeles

global blit

blit:

entrada_funcion 8 
     
completo:
  		
    mov edi, ptrSprite					;edi apunta todo el tiempo a la posicion dentro de sprite
    
    ;esi <-- coord_y*(3*SCREEN_W + basura) + coord_x*3 + screen_pixeles
    
    mov esi, [screen_pixeles]			;cargo el puntero a pantalla en esi
		calcular_pixels ecx, coord_x	;cargamos la coor x en edx y lo multiplicamos por 3
    add esi, ecx									;le addiciono el valor de la coord_x a screen_pixeles
    mov eax, coord_y							;cargo la coord y en eax
    
    calcular_pixels edx, SCREEN_W						;cargamos el ancho de la pantalla en edx y lo multiplicamos por 3
		calcular_basura ebx,edx 								;calculo la basura en ebx, desde edx
    add edx, ebx														;sumo el valor de la basura a edx
		mov ancho_screen_bytes,edx
						
    mul edx
    add esi, eax									;eax posee la cantidad de bytes q hay q sumarle al puntero a screen
    
    mov eax, altoSprite
    mul edx												;guardo en ecx la cantidad de bytes q usa el sprite							
    add eax, esi									;sumo el punto (0,0)
    mov final, eax
    
;edi apunta todo el tiempo a la posicion dentro de la pantalla
nueva_fila:		
		 								
  mov ecx, anchoSprite
      
;las coordenadas (x, y) (x+p, y) (x, y+q) (x+p, y+q)

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
	ror eax, 8
	cmp ax, bx
	jne no_cambio_color

	;cambio el color_off por el fondoa
	mov bl, [esi] 		;edi es el puntero al byte actual del screen
	mov [edi], bl
	
	mov bx, [esi + 1] 		
	mov [edi + 1], bx
	
no_cambio_color:	 
	add edi, 03h
	add esi, 03h
	loopne while
	
	calcular_pixels ebx, anchoSprite
	calcular_basura edx,ebx
	add edi, ebx
	sub esi, ebx
	mov edx, ancho_screen_bytes
	add esi, edx	; edx queda apuntando al principio de la siguiente fila
	
	cmp edi, final
	je finBlit
	
	jmp nueva_fila
 
finBlit:
  
salida_funcion 4

