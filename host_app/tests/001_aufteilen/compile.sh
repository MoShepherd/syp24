#gcc -o main auswahlmenue.c bootloader.c configserial.c filechooser.c get_filepath.c main.c -lncurses
gcc -o bin/main src/*.c  -lncurses

