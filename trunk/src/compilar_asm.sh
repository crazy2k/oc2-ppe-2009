cd ./asm/
rm *.o

for i in ./*
do
    nasm -f elf "$i"
done

cd ..
