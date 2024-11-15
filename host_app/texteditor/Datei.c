#include "Datei.h"

int y_offset = 0;
int t_offset = 0;

void Datei(DATEI *d, char *filename, int size){
    d->text = (LINE *)malloc(size * sizeof(LINE));

    for(int i=0; i<size; i++){
        editLine(d->text + i);
    }
    strcpy(d->filename, filename);
    d->numlines = 0;
    d->size = size;
}

void delDatei(DATEI *d){
    for(int i=0;i<d->numlines; i++){
        free(d->text[i].line);
    }
    free(d->text);
}

void insertLine(DATEI *d, int index){
    LINE newLine;
    editLine(&newLine);
    newLine.line[0] = '\0';

    for(int i=d->numlines; i>=index; i--){
        d->text[i+1] = d->text[i];
    }

    d->text[index] = newLine;
    (d->numlines)++;
}

void removeLine(DATEI *d, int index){
    if(d->numlines > 1){
        free(d->text[index].line);
        for(int i=index; i < d->numlines-1; i++){
            d->text[i] = d->text[i+1];
        }
        (d->numlines)--;
    }
}

void printDatei(const DATEI *d, int start, int end){
    int line;
    for(int i=start, line=0; i<d->numlines && i < end; i++, line++){
        move(line, 0);
        clrtoeol();
        printw("%s", d->text[i].line);

    }

    if(start < end){
        move(line, 1);
        clrtoeol();
        move(line-1, 1);
    }
    refresh();
}

int getLines(FILE *f){
    char end = '\0';
    int count = 0; // Z�hlt die Anzahl der Zeilen
    while((end = fgetc(f)) != EOF){
        if(end == '\n'){
            count++;
        }
    }
    fseek(f, 0, SEEK_SET);
    return count;
}

int fileExists(char *filename){
    FILE *f = fopen(filename, "r");
    if(f != NULL){
        fclose(f);
        return 1;
    }
    return 0;
}

void loadFile(DATEI *d, char* filename){
    FILE *f = fopen(filename, "r");
    int size = getLines(f) * 2; // warum *2? (500)
    char end = '\0';
    int line;

    Datei(d, filename, size);

    for(line = 0; line < size && end != EOF; line++){
        end = fgetc(f);
        while(end != '\n' && end != EOF){
            LINE *currentLine = &(d->text[line]);

            if(end != '\t'){
                insertCharToEndOfLine(currentLine, end);
            } else {
                for(int i=0; i<4; i++){ // 4=So lang wie Tabtaste ist
                    insertCharToEndOfLine(currentLine, ' ');
                }
            }
            end = fgetc(f);
        }
        (d->numlines)++;
    }
}

void saveFile(DATEI *d){
    FILE *f = fopen(d->filename, "w");

    for(int line = 0; line < d->numlines; line++){
        int col = 0;
        while(d->text[line].line[col] != '\0'){
            fputc(d->text[line].line[col], f);
            col++;
        }
        fputc('\n', f);
    }
    fclose(f);
}

void moveLeft(int *x, int *y){
    if(*x - 1 > 0){
        move(*y, --(*x));
    }
}

void moveRight(DATEI *d, int *x, int *y){
    if(*x <= strlen(d->text[*y + y_offset].line)){
        move(*y, ++(*x));
    }
}

void moveUp(DATEI *d, int *x, int *y){
    if(*y > 0){
        --(*y);
    } else if(y_offset > 0){
        --(y_offset);
        printDatei(d, 0+y_offset, WIN_SIZE + y_offset);
    }

    if(*x > strlen(d->text[*y + y_offset].line) + 1){
        *x = strlen(d->text[*y + y_offset].line) + 1;
    }
    move(*y, *x);
}

void moveDown(DATEI *d, int *x, int *y){
    if(*y < WIN_SIZE - 1 && *y < d->numlines - 1){
        ++(*y);
    } else if(*y + y_offset < d->numlines - 1){
        ++(y_offset);
        printDatei(d, 0 + y_offset, WIN_SIZE + y_offset);
    }

    if(*x > strlen(d->text[*y + y_offset].line) + 1){
        *x = strlen(d->text[*y + y_offset].line) + 1;
    }
    move(*y, *x);
}

void updateStatus(char *info){
    int oldy, oldx; getyx(stdscr, oldy, oldx);

	attron(A_REVERSE);
	move(LINES - 1, 0);
	clrtoeol();
	printw(info);
	attroff(A_REVERSE);

	move(oldy, oldx);
}
