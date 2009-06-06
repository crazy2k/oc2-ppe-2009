# Correrlo desde el directorio src/ del TP.
rm ./asm/*.o
for i in ./asm/*.asm
do
    nasm -g -f elf "$i"
done

