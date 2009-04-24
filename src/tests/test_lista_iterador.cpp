#include "SDL.h"
#include "math.h"
#include "../structs.h"

extern "C" Lista* constructor_lista();
extern "C" void inicializar_nodo(Nodo* nuevo, SDL_Surface *surfacePers, SDL_Surface *surfaceGen, Uint32 x, Uint32 y, Uint32 ID);
extern "C" bool verificar_id (Lista* la_lista, Uint32 id);
extern "C" void agregar_item_ordenado(Lista* la_lista, SDL_Surface* surfacePers, SDL_Surface* surfaceGen, Uint32 x, Uint32 y, Uint32 ID);
extern "C" void borrar(Lista* la_lista, Uint32 x, Uint32 y);
extern "C" void liberar_lista(Lista* l);

// Declaracion de la variable global para el iterador
extern "C" Iterador *iterador_lista;
extern "C" Iterador* constructor_iterador(Lista *lista);
extern "C" void proximo(Iterador *iter);
extern "C" Nodo* item(Iterador *iter);
extern "C" bool hay_proximo(Iterador *iter);
extern "C" void liberar_iterador(Iterador *iter);

int main() {
    Lista* l = constructor_lista();

    agregar_item_ordenado(l, NULL, NULL, (Uint32)3, (Uint32)0, (Uint32)3);
    agregar_item_ordenado(l, NULL, NULL, (Uint32)1, (Uint32)0, (Uint32)1);
    agregar_item_ordenado(l, NULL, NULL, (Uint32)2, (Uint32)0, (Uint32)2);

    Iterador* i = constructor_iterador(l);

    for (int x = 1; x <= 3; x++) {
        Nodo* n = item(i);
        printf("%d \n", n->coord_x);
        proximo(i);
    }
}
