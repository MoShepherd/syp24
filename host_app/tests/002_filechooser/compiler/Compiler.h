#ifndef Compiler_H
#define Compiler_H

#include <stdio.h>
#include <stdint.h>

typedef struct cmd {
    unsigned char pakettyp;
    unsigned char opCode;
    unsigned char adr;
} cmd;

extern const char *mnemonicMappings[][2];
extern const char *binaryMappings[][2];

//int main(int argc, char *argv[]);
int mnem2bin(char* filename);
int bin2mnem(char* filename);
void formatFile(char* filename);

#endif // Compiler_H