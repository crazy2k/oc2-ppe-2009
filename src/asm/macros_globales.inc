
extern malloc
extern free

%macro entrada_funcion 1
    push ebp
    
    push edi
    push esi
    push ebx
    
    mov ebp, esp

    %if %1 <> 0
    sub esp, %1
    %endif

%endmacro

%macro salida_funcion 1
    %if %1 <> 0
    add esp, %1
    %endif

    pop ebx
    pop esi
    pop edi

    pop ebp

    ret
%endmacro

%define parte_baja_id 0
%define parte_alta_id 4
%define surf_gen 8
%define surf_pers 12
%define coord_x 16
%define coord_y 20
%define prox 24
%define prev 28

%define SCREEN_W 800
%define SCREEN_H 400

 

