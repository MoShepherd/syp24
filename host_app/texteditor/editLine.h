#ifndef EDITLINE_H
#define EDITLINE_H

#include <string.h>
#include <stdlib.h>

#define MAX_LINE_SIZE 128

typedef struct {
    char *line;
    int size;
} LINE;

void editLine(LINE *s); // Initialisierung der Zeile
void insertCharToLine(LINE *s, char c, int index); // Zeichen an bestimmte Stelle der Zeile hinzuf�gen
void insertCharToEndOfLine(LINE *s, char c); // Zeichen ans Ende eines Strings hinzug�gen
void removeChar(LINE *s, int index); // Zeichen l�schen

#endif // EDITLINE_H
