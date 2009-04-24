
extern malloc

global constructor_lista
global inicializar_nodo
global verificar_id
global agregar_item_ordenado
global borrar
global liberar_lista

%macro entrada_funcion 1
    push ebp
    mov ebp, esp
    
    push edi
    push esi
    push ebx

    sub esp, %1

%endmacro

%macro salida_funcion 1
    add esp, %1

    pop ebx
    pop esi
    pop edi

    pop ebp

    ret
%endmacro

%define prox 196
 

section .data
    iterador_lista: dd FFFFh

section .text

constructor_lista:

    entrada_funcion 0

    xor eax, eax
    mov eax, 4

    push eax
    call malloc

    cmp eax, 0

    ; si malloc no me pudo dar memoria
    jeq retornar

    mov [eax], 0

retornar:
    salida_funcion 0


%define lista [ebp + 8]
%define id [ebp + 12]

verificar_id:
    entrada_function 0

    mov eax, lista           ;aca tengo el nodo* primero

seguir:

    mov ebx, [eax]           ;cargo la parte menos significativa del Id del nodo
    mov ecx, [eax+4]         ;porq ID es de 64 bits

    cmp ebx, id
    jne siguiente
    cmp ecx, 0
    jne siguiente

    mov eax, 0               ;se encontro el Id

    salida_funcion 0

siguiente: 
    mov eax, [eax+prox]
    cmp eax, 0
    jne seguir
    mov eax, 1

    salida_funcion 0



agregar_item_ordenado:

entrada_funcion 0


