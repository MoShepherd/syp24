#include <ncurses.h>
#include <stdlib.h>
#include <string.h>
#include "../includes/allefunktionen.h"

 
// in main.c deklarierte globale variablen
extern char* selected_file;
extern char* current_file; // modusFilechooser = 0
extern char* current_binary; // modusFilechooser = 1
extern int modusFilechooser; // welche File ausgewählt wird
extern int c; 

void bootloader(){
    int height, width;
    getmaxyx(stdscr, height, width);
    
    int wStart = (width - 12) / 10;
    int hStart = height / 8;

    int selectedRow = hStart;
    char *options [] = {"Current Binary: ", "(1) Load Binary", "(2) Execute", "(3) Upload to RAM", "(4) Load from FLASH", "(5) Load to FLASH", "> Zurück" };
    
    // Auswahl markieren
    for (int i = 0; i < 7; ++i) {
        if (i == selectedRow) {
            attron(COLOR_PAIR(1));
            mvprintw(hStart, wStart, options[i]);
            attroff(COLOR_PAIR(1));
        } else {
            mvprintw(hStart, wStart, options[i]);
        }
        hStart += 2;
    }
    
    refresh();

    // User Input
    while ((c = getch()) != 27) {  // Programm wird mit esc beendet
        switch (c) {
            case KEY_UP:
                if (selectedRow > 1) {
                    --selectedRow;
                }
                break;
            case KEY_DOWN:
                if (selectedRow < 6) { 
                    ++selectedRow;
                }
                break;
            case 10:  // Drücken der Enter-Taste
                if (selectedRow == 1) { // Load Binary
                    clear();
                    endwin();
                    filechooser();
                    initscr();
                    if(selected_file != NULL){
                        char* filepath = get_filepath();
                        mvprintw(height / 8, wStart + 16, filepath);
                    } else {
                        mvprintw(hStart, wStart, "< [!] ERROR: Es wurde keine Datei ausgewählt! >");
                    }
                    refresh();
                } else if (selectedRow == 2) { // Execute

                } else if (selectedRow == 3) { // Upload to RAM
                    
                } else if (selectedRow == 4) { // Load from FLASH
                    
                } else if (selectedRow == 5) { // Load to FLASH
                    
                } else if (selectedRow == 6) { // Zurück
                    clear();
                    auswahlmenu();
                }
                break;
        }

        // Auswahl markieren geupdated
        hStart = height / 8;
        for (int i = 0; i <= 6; ++i) {
            if (i == selectedRow) {
                attron(COLOR_PAIR(1));
                mvprintw(hStart, wStart, options[i]);
                attroff(COLOR_PAIR(1));
            } else {
                mvprintw(hStart, wStart, options[i]);
            }
            hStart += 2;
        }
        refresh();
    }
    clear();
};
