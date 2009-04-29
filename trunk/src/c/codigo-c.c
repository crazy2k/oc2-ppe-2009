#include <cstdlib>
#include "SDL.h"
#include "../structs.h"

#define SCREEN_WIDTH 800
#define SCREEN_HEIGHT 400

extern int g_ver0, g_ver1, g_hor0, g_hor1, colores[512];
extern Color* screen_pixeles;

bool color_igual(Color* a ,Color* b) { //*a == *b
    return a->r == b->r && a->g == b->g && a->b == b->b;
}

void copiar_color (Color* a ,Color* b) { //*a = *b
    a->r = b ->r;
    a->g = b ->g;
    a->b = b ->b;
}

extern "C" void generarPlasma (Color rgb)
{
  int x;
  for (int i = 0; i < SCREEN_HEIGHT; i++)
  {
     for (int j = 0; j < SCREEN_WIDTH; j++)
     {
         x = colores[(g_ver0 + 5*j) % 512] +
           colores[(g_ver1 + 3*j) % 512] +
           colores[(g_hor0 + 3*i) % 512] +
           colores[(g_hor1 + i) % 512];
         Uint8 index = 128 + (x >> 4);
         if (color_igual(&screen_pixeles[i * SCREEN_WIDTH + j],&rgb))
         {
             if (index < 64) {
                  screen_pixeles[i * SCREEN_WIDTH + j].r = 255 - ( (index << 2) + 1);
                  screen_pixeles[i * SCREEN_WIDTH + j].g = index << 2;
                  screen_pixeles[i * SCREEN_WIDTH + j].b = 0;
            } else if (index < 128) {
                  screen_pixeles[i * SCREEN_WIDTH + j].r = (index << 2) + 1;
                  screen_pixeles[i * SCREEN_WIDTH + j].g = 255;
                  screen_pixeles[i * SCREEN_WIDTH + j].b = 0;
            } else if (index < 192) {
                  screen_pixeles[i * SCREEN_WIDTH + j].r = 255 - ( (index << 2) + 1);
                  screen_pixeles[i * SCREEN_WIDTH + j].g = 255 - ( (index << 2) + 1);
                  screen_pixeles[i * SCREEN_WIDTH + j].b = 0;
            } else if (index < 256) {
                  screen_pixeles[i * SCREEN_WIDTH + j].r = (index << 2) + 1;
                  screen_pixeles[i * SCREEN_WIDTH + j].g = 0;
                  screen_pixeles[i * SCREEN_WIDTH + j].b = 0;
            } else if (index >= 256) {
                  screen_pixeles[i * SCREEN_WIDTH + j].r = 0;
                  screen_pixeles[i * SCREEN_WIDTH + j].g = 0;
                  screen_pixeles[i * SCREEN_WIDTH + j].b = 0;
            }
         }
     }
  }
  g_ver0 += 9;
  g_hor0 += 8;
}

extern "C" Lista* constructor_lista() {
    Lista *res = (Lista*) malloc(sizeof(Lista));
    res->primero = NULL;
    return res;
}

extern "C" bool verificar_id (Lista* la_lista, Uint32 id) {
    Nodo* sgte = la_lista->primero;
    while (sgte) {
        Nodo* prox = sgte->prox; 
        if (sgte->ID == id) return false;
        sgte = prox;
    }
    return true;
}

extern "C" bool conectar (Nodo* a, Nodo* b) {
    a->prox = b;
    b->prev = a;
}

extern "C" void agregar_item_ordenado(Lista* la_lista, SDL_Surface* surfacePers, SDL_Surface* surfaceGen, Uint32 x, Uint32 y, Uint32 ID) {
    Nodo *sgte, = la_lista->primero, *anterior = NULL;
    while (sgte && sgte->ID < ID)
        sgte = sgte->prox;
        
    if (sgte == NULL || (sgte->ID =! ID)) {
        Nodo* nuevo = (Nodo*) malloc(sizeof(Nodo));
        nuevo->ID = ID;
	    nuevo->surfaceGen = surfaceGen;
        nuevo->surfacePers surfacePers;
	    nuevo->coord_x = coord_x;
	    nuevo->coord_y = coord_y;
	    nuevo->prox = NULL;
	    nuevo->prev = NULL;
	    
	    if (sgte->prev) conectar(sgte->prev,nuevo);
	    else la_lista->primero = nuevo;
	    
        if (sgte) conectar(nuevo,sgte);
    }
}


extern "C" void borrar(Lista* la_lista, Uint32 x, Uint32 y) {
    Nodo *sgte, = la_lista->primero, *proximo = NULL;
    while (sgte) {
        proximo = sgte->prox;
        if ( abs(sgnt->coord_x - x) < 50 && abs(sgnt->coord_y - y) < 50 ) {
            if (sgte->prev == NULL) { 
                la_lista->primero = sgte->prox;
                if (sgte->prox != NULL) sgte->prox->prev = NULL;
            } else if (sgte->prox == NULL) sgte->prev->prox = NULL;
            else conectar(sgte->prev,sgte->prox);
            free(sgte);
        }
        sgte = proximo;
    }
}

extern "C" void liberar_lista(Lista* l) {
    Nodo* sgte = l->primero;
    while (sgte) {
        Nodo* prox = sgte->prox;
        free(sgte);
        sgte = prox;
    }
    free(l);
}

// Declaracion de la variable global para el iterador
extern "C" Iterador* constructor_iterador(Lista *lista) {
    Iterador* res = (Iterador*) malloc(sizeof(Iterador));
    res->actual = lista->primero;
    return res;
}

extern "C" void proximo(Iterador *iter) {
    iter->actual = iter->actual->prox;
}

extern "C" Nodo* item(Iterador *iter) {
    return iter->actual;
}

extern "C" bool hay_proximo(Iterador *iter){
    return iter->actual != NULL;
}

extern "C" void liberar_iterador(Iterador *iter) {
    free(iter);
}

extern "C" void generarFondo (Uint8 *fondo, Uint32 fondo_w, Uint32 fondo_h, Uint32 screenAbsPos);

/////
// Recorta de una tira de Sprites uno en particular
/////
//extern void recortar(Uint8 *imagen, Uint32 instancia, Uint32 ancho_instancia, Uint32 w, Uint32 h, Uint8 *res, bool dir);
extern "C" void recortar(Uint8* sprite, Uint32 instancia, Uint32 ancho_instancia, Uint32 ancho_sprite, Uint32 alto_sprite, Uint8* res, bool orientacion);
 //recortar(item(iter)->surfaceGen->pixels, ciclo%24, item(iter)->surfacePers->w, item(iter)->surfaceGen->w, item(iter)->surfaceGen->h, item(iter)->surfacePers->pixels, true);

/////
// Cambia el color off en una imagen por el color del Fondo
////
extern "C" void blit(Uint8 *image, Uint32 w, Uint32 h, Uint32 x, Uint32 y, Color rgb) {
    Color* comienzo = ((SCREEN_WIDTH) + x + screen_pixeles),
    pos_buff = (Color*) image;
    int basura = (w * 3) % 4;
    
    for (int i = 0; i < h; i++) {
        Color *final = comienzo + w, *actual = comienzo;
        for (int j = 0; j < w; j++, actual++, pos_buff++) {
        if (color_igual(*pix,rgb))
            copiar_color(pos_buff,actual);
        }
        pos_buff = (Color*) ((int) pos_buff + basura);
        comienzo += SCREEN_WIDTH;
    }        
}

