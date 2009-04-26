%include "./asm/macros_globales.inc"

global constructor_iterador
global hay_proximo
global proximo
global item
global liberar_iterador

section .text

%define const_it_lista [ebp + 8]
; Iterador* constructor_iterador(Lista *lista)
constructor_iterador:
    entrada_funcion 0

    mov eax, 4

    push eax
    call malloc
    add esp, 4

    cmp eax, 0

    ; si malloc no me pudo dar memoria
    je retornar

    mov ebx, const_it_lista     ; ebx = direccion que apunta a la Lista
    mov ebx, [ebx]              ; ebx = direccion que apunta al Nodo
    mov [eax], ebx              ; En el espacio creado en memoria guardo
                                ; la direccion que apunta al nodo.

retornar:
    salida_funcion 0


%define hay_prox_pit [ebp + 8]
; bool hay_proximo(Iterador *iter)
; Recordar: La especificacion de esta funcion en el enunciado esta _mal_.
; hay_proximo() es, mas bien, hay_actual()
hay_proximo:
    entrada_funcion 0
    xor eax, eax
    mov ebx, hay_prox_pit       ; ebx = direccion que apunta al Iterador
    mov ebx, [ebx]              ; ebx = direccion que apunta al Nodo actual
    ;cmp dword [ebx + prox], 0         ; el proximo es NULL?
    cmp ebx, 0            ; el actual es NULL?

    je es_null
    ; si no lo es, retorno 1
    mov eax, 1
es_null:
    salida_funcion 0
    
%define prox_pit [ebp + 8]
; void proximo(Iterador *iter)
proximo:
    entrada_funcion 0

    mov eax, prox_pit       ; eax = direccion que apunta al Iterador
    mov ebx, [eax]          ; ebx = direccion que apunta al Nodo actual
    mov ebx, [ebx + prox]   ; ebx = direccion que apunta al Nodo proximo
    cmp ebx, 0

    mov [eax], ebx

    salida_funcion 0

%define item_pit [ebp + 8]
; Nodo* item(Iterador *iter)
item:
    entrada_funcion 0

    mov eax, prox_pit       ; eax = direccion que apunta al Iterador
    mov eax, [eax]          ; ebx = direccion que apunta al Nodo actual
    salida_funcion 0


%define lib_pit [ebp + 8]
; void liberar_iterador(Iterador *iter)
liberar_iterador:
    entrada_funcion 0

    mov eax, lib_pit
    push eax
    call free
    add esp, 4

    salida_funcion 0


