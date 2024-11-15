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

void configserial(){
    int height, width;
    getmaxyx(stdscr, height, width);
    
    int wStart = (width - 12) / 10;
	int wStart2 = wStart + width / 4;
    int hStart = height / 8;
    int hStart2 = hStart + height / 2;
	int column;

    int selectedRow = hStart;
    int selectedRow2 = hStart2;

    int baudrate = 11500;
    char path[80] = "/dev/ttyACM0";
	char baudrateS[10];
	sprintf(baudrateS, "%d", baudrate);

    char *options [] = {baudrateS, path};
	char *buttons [] = {"> Abbrechen", "> OK"};

	mvprintw(hStart, wStart, "Baud");
	mvprintw(hStart + 2, wStart, "COMPort");

	column = wStart2;

    // BAUDRATE & COMPORTPATH
    for (int i = 0; i < 2; ++i) {
        if (i == selectedRow) {
            attron(COLOR_PAIR(1));
            mvprintw(hStart, column, options[i]);
            attroff(COLOR_PAIR(1));
        } else {
            mvprintw(hStart, column, options[i]);
        }
        hStart += 2;
    }
    refresh();

	column = wStart;

    // Abbrechen & OK
    for (int i = 0; i < 2; ++i) {
        if (i == selectedRow2) {
            attron(COLOR_PAIR(1));
            mvprintw(hStart2, column, buttons[i]);
            attroff(COLOR_PAIR(1));
        } else {
            mvprintw(hStart2, column, buttons[i]);
        }
        column = wStart2;
    }
    refresh();

    // User input
    while ((c = getch()) != 27) {  // Programm wird mit esc beendet
        switch (c) {
            case KEY_UP:
                if (selectedRow > 0) {
                    --selectedRow;
                }
                break;
            case KEY_DOWN:
                if (selectedRow < 1) { 
                    ++selectedRow;
                }
                break;
            case KEY_LEFT:
                if(selectedRow2 == hStart2 && column == wStart2) {
                    column = wStart;
                }
                break;
            case KEY_RIGHT:
                if(selectedRow2 == hStart2 && column == wStart) {
                    column = wStart2;
                }
                break;
            case 10:  // Drücken der Enter-Taste
                if (selectedRow == 0) { // BAUDRATE
                    scanw("%d", &baudrate);
                    mvprintw(hStart, wStart, options[0]);
                } else if (selectedRow == 1) { // COMPORTPATH
                    clear();
                    endwin();
                    filechooser(); // funktioniert gerade nicht, weil kein Filechooser-Modus für comportpath
                    initscr();
                    if(selected_file != NULL) {
                        char* comportpath = get_filepath();
                        mvprintw(height / 8 + 2, ((width - 12) / 10 + width / 4), comportpath);
                    } else {
                        mvprintw(hStart, wStart, "< [!] ERROR: Es wurde keine Datei ausgewählt! >");
                    }
                    refresh();
                } else if (selectedRow2 == hStart2 && column == wStart) { // Abbrechen
                    clear();
                    auswahlmenu();
                } else if (selectedRow == hStart2 && column == wStart2) { // OK
                    // speichern
                    clear();
                    auswahlmenu();
                }
                break;
        }

        // Auswahl markieren geupdated
        hStart = height / 8;
        for (int i = 0; i <= 1; ++i) {
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

        // Auswahl markieren geupdated
        column = wStart;
        for (int i = 0; i <= 1; ++i) {
            if (i == selectedRow2) {
                attron(COLOR_PAIR(1));
                mvprintw(hStart2, column, buttons[i]);
                attroff(COLOR_PAIR(1));
            } else {
                mvprintw(hStart2, column, buttons[i]);
            }
            column = wStart2;
        }
        refresh();
    }
    clear();
}
