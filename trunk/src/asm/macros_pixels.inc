
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
    and %1, 3h				         						;la basura del fondo bmp
%endmacro

