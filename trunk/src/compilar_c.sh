# Correrlo desde el directorio src/ del TP.
rm ./c/*.o

g++ -c `sdl-config --cflags --libs` c/codigo-c.c -o c/codigo-c.o
