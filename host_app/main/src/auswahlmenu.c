#include <ncurses.h>
#include <stdlib.h>
#include <string.h>
#include "../includes/allefunktionen.h"
#include "../../compiler/Compiler.h"

// in main.c deklarierte globale variablen
extern char* current_file; // modusFilechooser = 0
extern char* current_binary; // modusFilechooser = 1
extern int modusFilechooser; // welche File ausgewählt wird
extern int c; // fürs switch-case

/**
 * \brief auswahlmenu(): Auswahlmenü wird geöffnet; Startseite
 * 
 * Das Auswahlmenü dient als Startseite und dort wird dem User ein Überblick der Optionen angezeigt,
 * sowie der Pfad der Datei, die man unter "Load Mnemonics" auswählt
 * 
 * Die Applikation beendet man durch Drücken von 'Esc'.
 * 
 * @todo Wenn man debugger() schließt und 'Esc' drückt, wird die Applikation nicht beendet, sondern es treten Bugs auf.
 * @todo evtl. "EXIT"-Option
*/
void auswahlmenu(){
    initscr();
    int height, width;
    getmaxyx(stdscr, height, width);
    
    int wStart = (width - 12) / 10;
    int hStart = height / 8;

    int selectedRow = hStart;
    char *options [] = {"Current File: ", "[Config Serial]", "[Load Mnemonics]", "[Bootloader]", "[Debugger]", "[Compile]" };
    
    // show current selected mnemo
    if(current_file != NULL) {
        mvprintw(height / 8, wStart + 14, current_file);
        refresh(); 
    }

    // Auswahl markieren
    for (int i = 0; i < 6; ++i) {
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
    
    // User input
    while ((c = getch()) != 27) {  // Programm wird mit esc beendet
        switch (c) {
            case KEY_UP:
                if (selectedRow > 1) {
                    --selectedRow;
                }
                break;
            case KEY_DOWN:
                if (selectedRow < 5) { 
                    ++selectedRow;
                }
                break;
            case 10:  // Drücken der Enter-Taste
                if (selectedRow == 1) { // Config Serial
                    //clear();
                    endwin();
                    clear();
                    configserial();
                } else if (selectedRow == 2) { // Load Mnemonics
                    clear();
                    endwin();
                    filechooser();
                    initscr();
                    modusFilechooser = 0;
                    if(current_file != NULL) {
                        mvprintw(height / 8, wStart + 14, current_file);
                    } else {
                        mvprintw(hStart, wStart, "< [ err ] No file has been chosen! >");
                    }
                    refresh();
                } else if (selectedRow == 3) { // Bootloader
                    clear();
                    bootloader();
                } else if (selectedRow == 4) { // Debugger
                    if(current_file != NULL){ // kann nur ausgewählt werden, wenn man eine Datei ausgewählt hat (Load Mnemonics)
                        clear();
                        debugger();
                    } else {
                        mvprintw(hStart, wStart, "< [ err ] No file has been chosen! >");
                    }
                } else if (selectedRow == 5) { // Compile
                    int retValue = mnem2bin(current_file);
                    if(retValue == 0){
                        mvprintw(hStart, wStart, "< [  !  ] Binary image has been created! >");
                    } else {
                        mvprintw(hStart, wStart, "< [ err ] Compiling has failed! >");
                    }
                }
                break;
        }
        // dynamisches Fenster (Resizing)
        int new_height, new_width;
        getmaxyx(stdscr, new_height, new_width);

        // Prüfen, ob eine Größenänderung stattgefunden hat
        if (new_height != height || new_width != width) {
            clear();
            refresh();
            height = new_height;
            width = new_width;                
        }

        // Auswahl markieren aktualisieren
        hStart = height / 8;
        for (int i = 0; i <= 5; ++i) {
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
}