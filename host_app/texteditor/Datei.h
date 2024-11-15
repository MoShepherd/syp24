#ifndef DATEI_H
#define DATEI_H

#define NAME_LIMIT 128
#define MAX_FILE_SIZE 500
#define WIN_SIZE (LINES-2)

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <ncurses.h>
#include "editLine.h"

typedef struct {
    char filename[NAME_LIMIT];
    LINE *text;
    int numlines;
    int size;
} DATEI;

void Datei(DATEI *d, char *filename, int size);
void delDatei(DATEI *d); //
void insertLine(DATEI *d, int index); // Neue Zeile hinzuf�gen
void removeLine(DATEI *d, int index); // Zeile l�schen
void printDatei(const DATEI *d, int start, int end);
int getLines(FILE *f);

int fileExists(char *filename);
void loadFile(DATEI *d, char* filename);
void saveFile(DATEI *d);

void moveLeft(int *x, int *y);
void moveRight(DATEI *d, int *x, int *y);
void moveUp(DATEI *d, int *x, int *y);
void moveDown(DATEI *d, int *x, int *y);

void updateStatus(char *info);
#endif // DATEI_H
