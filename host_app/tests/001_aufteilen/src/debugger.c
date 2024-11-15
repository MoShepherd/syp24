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

void debugger(){
    //wrefresh(curscr);
    int height, width;
    getmaxyx(stdscr, height, width);
    
    char options[175] = "(b) BP setzen - (d) BP löschen - (z) zurück - (e) Einzelschritt - (r) Read RAM - (w) Write RAM - (c) continue - (f) Read Register - (s) Write Register - (q) Quit Debugger";

    int wStart = (width - 12) / 10;
    int hStart = height - height / 5;

    mvprintw(hStart, wStart, options);
    refresh();

    // User Input
    while ((c = getch()) != 27) {  // Programm wird mit esc beendet
        switch (c) {
            case 98: // (b) BP setzen
                break;
            case 100: // (d) BP löschen
                break;
            case 122: // (z) zurück
                break;
            case 101: // (e) Einzelschritt
                //if(){ // Error tritt auf
                //    mvprintw(hStart+1, wStart, "< [!] ERROR: Einzelschritt konnte nicht ausgeführt werden! >");
                //}
                break;
            case 114: // (r) Read RAM
                //if(){ // nicht im CPU-Halt
                //    mvprintw(hStart+1, wStart, "< [!] ERROR: CPU muss angehalten sein! >");
                //}
                break;
            case 119: // (w) Write RAM
                //if(){ // nicht im CPU-Halt
                //    mvprintw(hStart+1, wStart, "< [!] ERROR: CPU muss angehalten sein! >");
                //}
                break;
            case 99: // (c) continue
                //if(){ // nicht im CPU-Halt
                //    mvprintw(hStart+1, wStart, "< [!] ERROR: CPU muss angehalten sein! >");
                //}
                break;
            case 102: // (f) Read Register
                //if(){ // nicht im CPU-Halt
                //    mvprintw(hStart+1, wStart, "< [!] ERROR: CPU muss angehalten sein! >");
                //}
                break;
            case 115: // (s) Write Register
                //if(){ // nicht im CPU-Halt
                //    mvprintw(hStart+1, wStart, "< [!] ERROR: CPU muss angehalten sein! >");
                //}
                break;
            case 113: // (q) Quit Debugger
                clear();
                auswahlmenu();
                break;
        }
        refresh();
    }
    clear();
};