#include "editLine.h"

void editLine(LINE *s){
    s->size = MAX_LINE_SIZE;
    s->line = (char *)malloc(s->size * sizeof(char));
    s->line[0] = '\0';
}

void insertCharToLine(LINE *s, char c, int index){
    for(int i=strlen(s->line); i>=index; i--){
        s->line[i+1] = s->line[i];
    }
    s->line[index] = c;
}

void insertCharToEndOfLine(LINE *s, char c){
    insertCharToLine(s, c, strlen(s->line));
}

void removeChar(LINE *s, int index){
    for(int i=index; i<strlen(s->line); i++){
        s->line[i] = s->line[i+1];
    }
}
