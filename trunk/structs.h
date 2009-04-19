// Estructura para la Lista de Items

struct Nodo
{
	Uint64	ID;
	SDL_Surface	*surfaceGen;
	SDL_Surface *surfacePers;

	Uint32	coord_x;
	Uint32	coord_y;
	Nodo*	prox;
	Nodo*	prev;
};

struct Lista
{
	Nodo* primero;
};

struct Color
{
	Uint8 r;
	Uint8 g;
	Uint8 b;
};


// Iterador de la Lista

struct Iterador
{
	Nodo *actual;
};