%include "macros_globales.asm"

global constructor_lista
global inicializar_nodo
global verificar_id
global agregar_item_ordenado
global borrar
global liberar_lista


section .text

; Lista* constructor_lista()
constructor_lista:

    entrada_funcion 0

    push 4
    call malloc
    add esp, 4

    cmp eax, 0

    ; si malloc no me pudo dar memoria
    je retornar

    mov dword [eax], 0

retornar:
    salida_funcion 0


%define verif_lista [ebp + 8]
%define verif_id [ebp + 12]

; bool verificar_id (Lista* la_lista, Uint32 id)
verificar_id:
    entrada_funcion 0

    mov eax, verif_lista ;aca tengo el nodo* primero

ver_seguir:

    mov ebx, [eax]           ;cargo la parte menos significativa del Id del nodo
    mov ecx, [eax+4]         ;porq ID es de 64 bits

    cmp ebx, verificar_id
    jne siguiente
    cmp ecx, 0
    jne siguiente

    mov eax, 0               ;se encontro 
    salida_funcion 0

siguiente: 
    mov eax, [eax+prox]
    cmp eax, 0
    jne ver_seguir
    mov eax, 1

    salida_funcion 0

%macro connect_nodos 2   ; 1 y 2 registros apuntando a nodos
    mov [%1 + prox], %2
    mov [%2 + prev], %1
%endmacro


%macro asignar_miembro 3-5 edi,esi   ; 1->2 = 3 (4 y 5 reg auxiliares)
    lea %4, [%1 + %2]
    mov %5, %3
    mov dword [%4],%5 
%endmacro

%define ag_lista [ebp + 8]
%define ag_surf_pers [ebp + 12]
%define ag_surf_gen [ebp + 16]
%define ag_x [ebp + 20]
%define ag_y [ebp + 24]
%define ag_id [ebp + 28]
; void agregar_item_ordenado(Lista* la_lista, SDL_Surface* surfacePers,
; SDL_Surface* surfaceGen, Uint32 x, Uint32 y, Uint32 ID);
agregar_item_ordenado:

    entrada_funcion 0
    push 32
    call malloc                   ; creo el nodo que voy a agregar
    add esp, 4
    cmp eax, 0
    jne inicializar
    salida_funcion 0

inicializar:
    ; inicializo la estructura del nodo
    asignar_miembro eax,parte_baja_id,ag_id

    mov dword[eax + parte_alta_id], 0

    asignar_miembro eax,surf_gen,ag_surf_gen

    asignar_miembro eax,surf_pers,ag_surf_pers

    asignar_miembro eax,coord_x,ag_x

    asignar_miembro eax,coord_y,ag_y

    mov dword [eax + prox], 0

    mov dword [eax + prev], 0


; en eax esta todo el tiempo el puntero al nodo nuevo y en ebx esta el puntero al nodo actual
inicio:
    mov edx, ag_lista           ; cargo en edx el puntero a la lista
    mov ebx, [edx]              ; cargo en ebx el puntero al primer nodo de la lista
    cmp ebx, 0                  ; reviso si la lista esta vacia

    jz insertar_primer_nodo     ; si no hay ningun nodo, agregar el nuevo (eax) al principio

    mov ecx, [ebx + coord_x]    ; guardo en ecx la coord x del primer nodo
    cmp ag_x, ecx               ; reviso si la coord x del primer nodo es menor a la que me pasaron por parametro
    jg ag_seguir                   ; mayor sin signo?

;esta guardado en edx la dir de la lista y en ebx la dir del primer nodo
caso_va_primero: 
    connect_nodos eax,ebx       ; pongo el elemento en eax antes del q esta en ebx
    jmp insertar_primer_nodo    ; guardo en la lista un puntero al nuevo nodo (eax)
    salida_funcion 0

ag_seguir:                         ; ebx tiene un puntero al nodo actual
    cmp dword[ebx + prox], 0    ; me fijo si hay prox
    jmp caso_va_al_final        ; No hay proximo
    
    mov edx, ebx                ; salvo en edi el nodo actual
    mov ebx, [ebx + prox]       ; Muevo ebx al proximo elemento
    mov ecx, [ebx + coord_x]    ; Guardo en ecx la coord x del siguiente nodo
    cmp ag_x, ecx
    jg ag_seguir                   ; Si nodo_actual.x > nodo_nuevo.x sigo buscando
   
    connect_nodos edx,eax        ; pongo el elemento nuevo (eax) despues del nodo actual (edx)
    connect_nodos eax,ebx        ; pongo el elemento nuevo (eax) antes del proximo (ebx)
    salida_funcion 0

caso_va_al_final:               ; ebx tiene un puntero al ultimo
    connect_nodos ebx,eax        ; pongo el elemento nuevo (eax) despues del nodo actual (ebx)
    salida_funcion 0
    
insertar_primer_nodo:
    mov [edx], eax              ; guardo en la lista el puntero al nodo nuevo
    salida_funcion 0



%macro en_rango 2-3 50 ; 1: direccion de memoria del centro del rango 2: direccion de memoria del valor a chequear
    mov edi, %1
    sub edi, %3 ; en edi esta la cota inferior

    mov esi, %2 ; en esi esta el valor a chequear
    cmp edi, esi
    jg %%no_esta

    add edi, %3*2 ; ahora en edi esta la cota superior
    cmp %2, edi
    jg %%no_esta

    mov edi, 0
    jmp %%esta 
%%no_esta:
    mov edi, 1
%%esta:
    cmp edi, 0

%endmacro

%define b_lista [ebp + 8]
%define b_x [ebp + 12]
%define b_y [ebp + 16]
; void borrar(Lista* la_lista, Uint32 x, Uint32 y)
borrar:
    entrada_funcion 0
    
    mov edx, b_lista            ; cargo en edx el puntero a la lista
    mov ebx, [edx]              ; cargo en ebx el puntero al primer nodo de la lista
b_seguir:
; asumo q en ebx esta siempre el puntero al nodo actual y en edx el puntero a la lista
    cmp ebx, 0
    jne revisar_rango            ; reviso si la lista esta vacia
    salida_funcion 0

; si no esta vacia
revisar_rango:
    en_rango b_x,[ebx + coord_x]
    jne avanzar
    en_rango b_y,[ebx + coord_y]
    jne avanzar

; eax - ebx - ecx y elimino ebx
eliminar_elemento:
    mov ecx, [ebx + prox]       ; guardo en ecx el nodo siguiente al actual
    mov eax, [ebx + prev]       ; guardo en ecx el nodo anterior al actual

    push ebx
    call free
    add esp, 4

    cmp eax, 0
    je caso_primer_elemento
    cmp ecx, 0
    je caso_ultimo_elemento

caso_elemento_intermedio:
    connect_nodos eax,ecx
    jmp avanzar

caso_primer_elemento:
    mov [edx], ecx              ; edx es la pos de memoria donde esta la lista
    cmp ecx, 0
    je avanzar                  ; si no hay proximo elemento sigo de largo
    mov dword [ecx + prev], 0   ; pongo en null al prev del nuevo primero
    jmp avanzar

caso_ultimo_elemento:
    mov dword [eax + prox], 0   ; pongo en null al prev del nuevo primero
    
avanzar:
    mov ebx, ecx
    jmp b_seguir
    

