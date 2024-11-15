#include <ncurses.h>
#include <stdlib.h>
#include <string.h>

#define MAX_BUFFER_SIZE 1024
#define COLOR_MATRIX_GREEN 8

// globale variablen werden hier deklariert
char* selected_file = NULL; // kommt später evtl weg, gerade noch für comportpath, aber eigentlich total useless, weil wird nicht genutzt
char* current_file = NULL; // modusFilechooser = 0
char* current_binary = NULL; // modusFilechooser = 1
int modusFilechooser; // welche File ausgewählt wird
int c; // fürs switch-case

int main() {
    initscr();
    raw();
    keypad(stdscr, TRUE);
    noecho();

    // Fehlermeldung falls Farben nicht unterstützt werden
    if (has_colors() == FALSE) {
        endwin();
        printf("< [!] ERROR: Dein Terminal unterstützt keine Farben! >");
    }
    
    start_color();
    init_color(COLOR_MATRIX_GREEN, 12, 628, 384); // Matrix Grün
    init_pair(1, COLOR_WHITE, COLOR_MATRIX_GREEN);  // Farben für Markierung

    auswahlmenu();
}
