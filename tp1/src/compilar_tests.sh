# Correrlo desde el directorio src/ del TP.
g++ -g `sdl-config --cflags --libs` -o test_lista_iterador ./tests/test_lista_iterador.cpp ./asm/funciones_lista.o ./asm/funciones_iterador.o
