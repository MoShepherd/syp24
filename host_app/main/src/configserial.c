#include <ncurses.h>
#include <termios.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <stdio.h>
#include "../includes/statusbar.h"
#include "../includes/config.h"
#include "../../uart/include/uart.h"
#include "../includes/allefunktionen.h"

#define MAX_BUFFER_SIZE 1024

// in main.c deklarierte globale variablen
extern int c; // fürs switch-case
extern char comport_path [MAX_BUFFER_SIZE];
extern int baud; 
extern int fd_uart;

// file handle for config file
extern const char *config_file;

// data structure that holds the config
extern struct Config config;

/**
 * \brief configserial(): Seite vom Menüpunkt "config serial" wird geöffnet.
 * 
 * Nach Aufruf werden im Terminal zwei neue Optionen angezeigt,
 * - die erste zeigt die baudrate bzw. gibt die Möglich eine serielle Konfiguration vorzunehmen um mit dem FPGA dei Verbindung zu erstellen.
 * - die zweite Option gibt die Möglichkeit eine USB Schnittstelle zu definieren für die Verbindung mit dem FPGA
 * @todo -
*/

void configserial() {
    initscr();
    raw();
    keypad(stdscr, TRUE);
    noecho();
    start_color();
    init_color(COLOR_MATRIX_GREEN, 12, 628, 384); // Matrix Grün
    init_pair(1, COLOR_WHITE, COLOR_MATRIX_GREEN);  // Farben für Markierung
    clear();
    int height, width;
    getmaxyx(stdscr, height, width);

    // read config file, if existent
    readConfigFromFile(config_file);

    int comport_selected = 0;

    int wStart = (width - 12) / 10;
    int wStart2 = (width - 12) / 3;

    int hStart = height / 8;

    int selectedRow = 0;
    int selectedCol = wStart2; // Startposition für den Cursor
    
    char baudrateS [80];
    char tempPath [MAX_BUFFER_SIZE] = "[...]";
    if(comport_path == NULL){
        comport_path[0] = '\0';
    }
    if (comport_path == NULL || comport_path[0] == '\0') {
        strncpy(comport_path, tempPath, MAX_BUFFER_SIZE - 1); 
    }else{ 
        strncpy(tempPath, comport_path, MAX_BUFFER_SIZE - 1); 
        tempPath[MAX_BUFFER_SIZE - 1] = '\0';
    }

    if (baud<=0){
        strcpy(baudrateS, "[...]");
    }else{
        sprintf(baudrateS, "%d", baud);
    }
    
    char *options[] = {baudrateS, comport_path};
    char *options2[] = {"Baud", "COMPort"};

    int optLen = sizeof(options) / sizeof(options[0]);
    int optLen2 = sizeof(options2) / sizeof(options2[0]);

    selectedCol = wStart;

    // Initialisierung des Fensters
    for (int i = 0; i < optLen; ++i) {
        mvprintw(hStart, wStart, options2[i]);
        selectedCol = wStart2;
        if (selectedRow == i && selectedCol == wStart2){
            attron(COLOR_PAIR(1));
            mvprintw(hStart, wStart2, options[i]);
            attroff(COLOR_PAIR(1));
        }else{
            mvprintw(hStart, wStart2, options[i]);
        }
             
        hStart += 4;
    }

    refresh();

    // User input
    while ((c = getch()) != 27) {  // Programm wird mit esc beendet
        selectedCol = wStart2;
        switch (c) {
            case KEY_UP:
                if (selectedRow > 0) {
                    --selectedRow;
                }
                break;
            case KEY_DOWN:
                if (selectedRow < optLen) {
                    ++selectedRow;
                }
                break;
            case 10:  // Drücken der Enter-Taste
                if (selectedRow == 0) {
                    echo();  // Ermöglicht das Sehen der Eingabe
                    mvprintw(hStart + 4, wStart, "Enter Baudrate: ");
                    getnstr(baudrateS, sizeof(baudrateS) - 1);  // Eingabe lesen
                    noecho();
                    int temp;
                    if (sscanf(baudrateS, "%d", &temp) == 1) {
                        baud = temp;  // Zuweisung, wenn Eingabe gültig ist
                    }else{
                        strcpy(baudrateS, "invalid Input!");
                    }
                    clear();
                } else if (selectedRow == 1) { 
                    echo();
                    mvprintw(hStart + 8, wStart, "Enter COMPort Path: ");
                    getnstr(tempPath, MAX_BUFFER_SIZE - 1);
                    noecho();
                    strncpy(comport_path, tempPath, MAX_BUFFER_SIZE - 1);
                    comport_path[MAX_BUFFER_SIZE - 1 ] = '\0';                   
                    clear();
                    comport_selected = 1;
                }
                break;
        }

        int new_height, new_width;
        getmaxyx(stdscr, new_height, new_width);

        if (new_height != height || new_width != width) {
                
            // Bereinigen und Fenster neu erstellen, um Flackern zu vermeiden
            clear();
            refresh();
            height = new_height;
            width = new_width;                
        }
        
        hStart = height/8;
        wStart = (width - 12) / 10;
        wStart2 = (width - 12) / 3;
        
        for (int i =0; i< optLen; ++i){
            mvprintw(hStart, wStart, options2[i]);
            selectedCol = wStart2;
            if (selectedRow == i && selectedCol == wStart2){
                attron(COLOR_PAIR(1));
                mvprintw(hStart, wStart2, options[i]);
                attroff(COLOR_PAIR(1));
            }else{
                mvprintw(hStart, wStart2, options[i]);
            }
                
            hStart += 4;
        }

        refresh();
    }

    clear();

    if(comport_selected){
        saveConfigToFile(config_file);
        // uart config
        // close if already open
        if(fd_uart > 0){
            close(fd_uart);
        }
        fd_uart = open(comport_path, O_RDWR | O_NOCTTY | O_SYNC);

        if (fd_uart < 0) {
            printStatusLine("[ err ] Could not open serial port!");
        }else {
            set_interface_attribs(fd_uart, B115200, 0);
        }
    }
}