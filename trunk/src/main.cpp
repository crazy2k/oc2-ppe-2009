#include "SDL.h"
#include "math.h"
#include "structs.h"

#define FRAMES_PER_SECOND 30
#define SCREEN_W 800
#define SCREEN_H 400


// Variables GLOBALES para el puntero a pantalla
SDL_Surface *screen;
Uint8 *screen_pixeles;


// Variables para Generar el Efecto de Plasma en el cielo
int colores[512];

Uint16	g_ver0, 
		g_ver1, 
		g_hor0, 
		g_hor1;
/////////

/// Funciones para el fondo de Plasma
/////
// Inicializa la Paleta de colores
/////
void init()
{
	int i;
	float rad;
 
	for (i = 0; i < 512; i++)
    {
		rad =  ((float)i * 0.703125) * 0.0174532;
		colores[i] = sin(rad) * 1024;
    }
}

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
/////
// Genera la parte est�tica del Fondo de acuerdo a una imagen seleccionada
////
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
extern "C" void blit(Uint8 *image, Uint32 w, Uint32 h, Uint32 x, Uint32 y, Color rgb);
/////
// Genera el Plasma
/////
//void generarPlasma(Color rgb);
extern "C" void generarPlasma(Color rgb);
// Funcion Smooth para difuminar el escenario cuando cambia
/////
extern "C" bool smooth();

extern "C" void negative();

// Funcion Negativo
/*void negative()
{
	Uint8* arriba;
	Uint8* abajo;
	Uint8* adelante;
	Uint8* atras;
	
	Uint8 cero = 0;

	Uint8* screenp = screen_pixeles;
	
	for (int i = 0; i < SCREEN_H; i++) //2
	{
		for (int j = 0; j < SCREEN_W*3; j++)  //6
		{
			((i > 0)? (arriba = screenp - SCREEN_W*3) : (arriba = &cero));
			((i < SCREEN_H-1)? (abajo = screenp + SCREEN_W*3) : (abajo = &cero));
			((j < SCREEN_W*3 - 1)? (adelante = screenp + 3) : (adelante = &cero));
			((j > 0)? (atras = screenp - 3) : (atras = &cero));
			
			float ar = (float)(*arriba)/(float)255.0;
			float ab = (float)(*abajo)/(float)255.0;
			float at = (float)(*atras)/(float)255.0;
			float ad = (float)(*adelante)/(float)255.0;
			
			float res = (1/sqrt((ar + ab + at + ad + 1)))*255;
			*screenp = (Uint8)res;
			
			screenp++;
		}
	}
}*/



//The timer
class Timer
{
    private:
    int startTicks;

    int pausedTicks;

    bool paused;

    bool started;

    public:
    Timer();

    void start();
    void stop();
    void pause();
    void unpause();

    int get_ticks();

    bool is_started();
    bool is_paused();
};

Timer::Timer()
{
    startTicks = 0;
    pausedTicks = 0;
    paused = false;
    started = false;
}

void Timer::start()
{
    started = true;

    paused = false;

    startTicks = SDL_GetTicks();
}

void Timer::stop()
{
    started = false;

    paused = false;
}

void Timer::pause()
{
    if( ( started == true ) && ( paused == false ) )
    {
        paused = true;

        pausedTicks = SDL_GetTicks() - startTicks;
    }
}

void Timer::unpause()
{
    if( paused == true )
    {
        paused = false;

        startTicks = SDL_GetTicks() - pausedTicks;

        pausedTicks = 0;
    }
}

int Timer::get_ticks()
{
    if( started == true )
    {
        if( paused == true )
        {
            return pausedTicks;
        }
        else
        {
            return SDL_GetTicks() - startTicks;
        }
    }
    return 0;
}

bool Timer::is_started()
{
    return started;
}

bool Timer::is_paused()
{
    return paused;
}

// End Class Timer
//

//////
// Main Principal
/////
int main(int argc, char *argv[]) 
{
	// Sprites Wolverine
	SDL_Surface *wolverine, *wolverineRecorte, *wolvStand, *wolvStandSec, *wolvFight, *wolvFightSec;
	SDL_Rect wolverineRect, wolvFightRec;

	// Manejo de Orientacion
	bool sentido = true;

	// Sprites de Items
	SDL_Surface *gambitStand, *gambit;
	SDL_Rect itemRec;
	
	// Sprites de Fondos
	SDL_Surface *fondoActual, *fondoUno, *fondoDos, *fondoTres;
	

	// Manejo de Escenarios
	int stage = 0, prev_stage = 0;


	// Rect de Sprites
	

	// Variables de Control de Tiempo para las Animaciones
	Uint32 ciclo = 0;
	Uint32 timePass = 0;
	Timer fps;


	// Manejo de posiciones Abstractas
	Uint32 wolverineAbsPos = 0;
	Uint32 screenAbsPos = 0;


	// Lista de Items de los escenarios
	Lista* items_fondo_uno = constructor_lista();
	Lista* items_fondo_dos = constructor_lista();

	//Lista* items_fondo_actual = constructor_lista();
	

	// Manejo de Eventos de la SDL
	SDL_Event event;
	
	bool biting = false;
	int count_bit = 0;
	int done=0;

	Uint8 *keys;
	
	atexit(SDL_Quit);

	// Iniciar SDL
	if (SDL_Init(SDL_INIT_VIDEO) < 0)
	{
		printf("No se pudo iniciar SDL: %s\n",SDL_GetError());
		exit(1);
	}

	// Activamos modo de video
	screen = SDL_SetVideoMode(SCREEN_W,SCREEN_H,24,SDL_SWSURFACE);
	if (screen == NULL)
	{
		printf("No se puede inicializar el modo gr�fico: \n",SDL_GetError());
		exit(1);
	}


	// Loading Sprites !
	wolverine = SDL_LoadBMP("imagenes/wolverine.bmp");
	if ( wolverine == NULL )
	{
		printf("No pude cargar gr�fico: %s\n", SDL_GetError());
		exit(1);
	}

	wolverineRecorte = SDL_LoadBMP("imagenes/wolveriner.bmp");
	if ( wolverineRecorte == NULL )
	{
		printf("No pude cargar gr�fico: %s\n", SDL_GetError());
        exit(1);
	}

	wolvStandSec = SDL_LoadBMP("imagenes/wolverineStandingSecuence.bmp");
	if ( wolvStandSec == NULL )
	{
		printf("No pude cargar gr�fico: %s\n", SDL_GetError());
        exit(1);
	}

	wolvStand = SDL_LoadBMP("imagenes/wolverineStanding.bmp");
	if ( wolvStand == NULL )
	{
		printf("No pude cargar gr�fico: %s\n", SDL_GetError());
        exit(1);
	}

	wolvFight = SDL_LoadBMP("imagenes/wolverineFight.bmp");
	if ( wolvFight == NULL )
	{
		printf("No pude cargar gr�fico: %s\n", SDL_GetError());
        exit(1);
	}

	wolvFightSec = SDL_LoadBMP("imagenes/wolverineFightSec.bmp");
	if ( wolvFightSec == NULL )
	{
		printf("No pude cargar gr�fico: %s\n", SDL_GetError());
        exit(1);
	}

	// Garga de Gambit (Item1)
	gambitStand = SDL_LoadBMP("imagenes/gambitStanding.bmp");
	if ( gambitStand == NULL )
	{
		printf("No pude cargar gr�fico: %s\n", SDL_GetError());
        exit(1);
	}

	gambit = SDL_LoadBMP("imagenes/gambit.bmp");
	if ( gambit == NULL )
	{
		printf("No pude cargar gr�fico: %s\n", SDL_GetError());
        exit(1);
	}

	// Carga de Fondos
	fondoUno = SDL_LoadBMP("imagenes/Fondo1.bmp");
	if ( fondoUno == NULL )
	{
		printf("No pude cargar gr�fico: %s\n", SDL_GetError());
        exit(1);
	}

	fondoDos = SDL_LoadBMP("imagenes/Fondo2.bmp");
	if ( fondoDos == NULL )
	{
		printf("No pude cargar gr�fico: %s\n", SDL_GetError());
        exit(1);
	}

	// Inicializamos los Sprites
	wolverineRect.x = wolverineAbsPos;
	wolverineRect.y = 300;


	// Inicializo la lista de Items del Mapa
	itemRec.x = 200-screenAbsPos;
	itemRec.y = 280;
	agregar_item_ordenado(items_fondo_uno, gambit, gambitStand, itemRec.x, itemRec.y, 0);
	
	itemRec.x = 400-screenAbsPos;
	itemRec.y = 280;
	agregar_item_ordenado(items_fondo_uno, gambit, gambitStand, itemRec.x, itemRec.y, 1);


	itemRec.x = 500 -screenAbsPos;
	itemRec.y = 280;
	agregar_item_ordenado(items_fondo_dos, gambit, gambitStand, itemRec.x, itemRec.y, 1);
	

	// Dibujando los items
	Iterador *iter;

	bool cambio_escenario = true;


	screen_pixeles = (Uint8*)screen->pixels;

	// Comenzamos el Ciclo del Juego
	while(done == 0)
	{
		
		fps.start();

		while (SDL_PollEvent(&event)) 
		{	
			if (event.type == SDL_QUIT) {done=1;}
					
			if (event.type == SDL_KEYDOWN || event.type == SDL_JOYBUTTONDOWN) {
						
				if (event.key.keysym.sym == SDLK_ESCAPE) {
					done=1;
				} 
			}
		}
		
		if (stage == 0) fondoActual = fondoUno;
		if (stage == 1) fondoActual = fondoDos;

		// Mostramos todo
		SDL_Flip(screen);
		
		// Generamos el fondo
		
		// Leyendo la entrada
		keys = SDL_GetKeyState(NULL);
		
		if (cambio_escenario) generarFondo((Uint8*)fondoActual->pixels, fondoActual->w, fondoActual->h, screenAbsPos);
		
		Color color_off;
		Color color_off_sprites;

		color_off_sprites.r = 255;
		color_off_sprites.b = 255;
		color_off_sprites.g = 0;


		if (stage == 0)
		{
			color_off.r = 248;
			color_off.g = 0;
			color_off.b = 248;
		}else
		{
			color_off.r = 255;
			color_off.g = 255;
			color_off.b = 255;
		}

		// Fondo de Plasma
		init();
		
		generarPlasma(color_off);

	
		if (stage == 0) iter = constructor_iterador(items_fondo_uno);
		if (stage == 1) iter = constructor_iterador(items_fondo_dos);
		while ( hay_proximo(iter) )
		{
			itemRec.x = item(iter)->coord_x-screenAbsPos;
			itemRec.y = item(iter)->coord_y;
			recortar((Uint8*)item(iter)->surfaceGen->pixels, ciclo%24, item(iter)->surfacePers->w, item(iter)->surfaceGen->w, item(iter)->surfaceGen->h, (Uint8*)item(iter)->surfacePers->pixels, true);
			blit((Uint8*)item(iter)->surfacePers->pixels, item(iter)->surfacePers->w, item(iter)->surfacePers->h, itemRec.x, itemRec.y, color_off_sprites);
			SDL_BlitSurface(item(iter)->surfacePers, NULL, screen, &itemRec);
			proximo(iter);
		}

		// Posicion de wolverine
		bool adelante = wolverineAbsPos >= 0 && wolverineAbsPos <= SCREEN_W/2-wolverineRecorte->w;
		bool atras = wolverineAbsPos <= fondoActual->w-wolverineRecorte->w && wolverineAbsPos >= fondoActual->w - SCREEN_W/2-wolverineRecorte->w;
		
		

		if (keys[SDLK_1] || keys[SDLK_3] || wolverineAbsPos >= fondoActual->w-wolverineRecorte->w || (wolverineAbsPos <= 2 && fondoActual != fondoUno) ) cambio_escenario = false;

		if (keys[SDLK_SPACE] && !biting)
		{
			biting = true;
			count_bit = 0;
			if (stage == 0)
			{borrar(items_fondo_uno, wolverineAbsPos+100, wolverineRect.y);}else{borrar(items_fondo_dos, wolverineAbsPos+100, wolverineRect.y);}
		}

		if (biting)
		{
			wolvFightRec.x = wolverineRect.x;
			wolvFightRec.y = wolverineRect.y-61;
			recortar((Uint8*)wolvFightSec->pixels, count_bit/2, wolvFight->w, wolvFightSec->w, wolvFightSec->h, (Uint8*)wolvFight->pixels, true);
			blit((Uint8*)wolvFight->pixels, wolvFight->w, wolvFight->h, wolvFightRec.x, wolvFightRec.y, color_off_sprites);
			SDL_BlitSurface(wolvFight, NULL, screen, &wolvFightRec);
			count_bit++;
			biting = (count_bit != 11*2);
		}

		if (keys[SDLK_LEFT] && !biting)
		{
			sentido = false;
			recortar((Uint8*)wolverine->pixels, ciclo%15, wolverineRecorte->w, wolverine->w, wolverine->h, (Uint8*)wolverineRecorte->pixels, sentido);
			blit((Uint8*)wolverineRecorte->pixels, wolverineRecorte->w, wolverineRecorte->h, wolverineRect.x, wolverineRect.y, color_off_sprites);
			SDL_BlitSurface(wolverineRecorte, NULL, screen, &wolverineRect);
			if (adelante || atras)
			{
				wolverineRect.x-=3;
				if (wolverineAbsPos > 3 ) wolverineAbsPos-=3;
			}else
			{
				if (screenAbsPos >= 3) screenAbsPos-=3;
				wolverineAbsPos-=3;
			}
		}
		else
		{
			if (keys[SDLK_RIGHT] && !biting)
			{
				sentido = true;
				recortar((Uint8*)wolverine->pixels, ciclo%15, wolverineRecorte->w, wolverine->w, wolverine->h, (Uint8*)wolverineRecorte->pixels, sentido); 
				//Mostrar a Wolverine
				blit((Uint8*)wolverineRecorte->pixels, wolverineRecorte->w, wolverineRecorte->h, wolverineRect.x, wolverineRect.y, color_off_sprites);
				SDL_BlitSurface(wolverineRecorte, NULL, screen, &wolverineRect);
				if (adelante || atras)
				{
					if (wolverineRect.x <= screen->w-wolverineRecorte->w) wolverineRect.x+=3;
					wolverineAbsPos +=3;
				}else
				{
					if (screenAbsPos < fondoActual->w-screen->w) screenAbsPos+=3;
					if (wolverineAbsPos <= fondoActual->w-wolverineRecorte->w) wolverineAbsPos += 3;
				}
			}
			else
			{
				if (!biting)
				{
					recortar((Uint8*)wolvStandSec->pixels, ciclo%18, wolvStand->w, wolvStandSec->w, wolvStandSec->h, (Uint8*)wolvStand->pixels, sentido); 
					//Mostrar a Wolverine
					blit((Uint8*)wolvStand->pixels, wolvStand->w, wolvStand->h, wolverineRect.x, wolverineRect.y, color_off_sprites);
					SDL_BlitSurface(wolvStand, NULL, screen, &wolverineRect);
				}
			}
		}

		if (keys[SDLK_1] || keys[SDLK_3])
		{
			negative();
		}

        negative();
		if (!cambio_escenario) 
		{
			cambio_escenario = smooth();
			if (cambio_escenario)
				if (stage == 0)
				{stage = 1;}else{stage = 0;}
		}

		if (prev_stage != stage)
		{
			if (stage == 1)
			{
				// Posicion del personaje
				wolverineAbsPos = 20;
				screenAbsPos = 0;
				wolverineRect.x = 20;
			}else
			{
				// Posicion del personaje
				wolverineAbsPos = fondoUno->w - wolverineRecorte->w - 10;
				screenAbsPos = fondoUno->w - screen->w;
				wolverineRect.x = screen->w - wolverineRecorte->w - 10;
			}
		}

        if( fps.get_ticks() < 1000 / FRAMES_PER_SECOND )
        {
            SDL_Delay( ( 1000 / FRAMES_PER_SECOND ) - fps.get_ticks() );
        }
		if (timePass == 3) {ciclo++;timePass=0;}
		timePass++;
		
		// Actualizo el escenario
		prev_stage = stage;
   }

   liberar_iterador(iter);
   liberar_lista(items_fondo_uno);
   liberar_lista(items_fondo_dos);
	
   return 0;
}

