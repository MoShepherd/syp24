#include <ncurses.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <stdbool.h>
#include <fcntl.h>
#include <stdio.h>
#include "../includes/allefunktionen.h"
#include "../includes/config.h"
#include "../../compiler/Compiler.h"
#include "../../uart/include/uart.h"

#define MAX_BUFFER_SIZE 1024 ///< 1024 Buffer
#define COLOR_MATRIX_GREEN 8 ///< Farbe Matrix Grün fürs Highlighting

// defines for uart config
#define TIMEOUT_VAL 200 // timeout in ms -- unnessecary!

/**
 * \brief main(): Ausführung.
 * 
 * die Main beinhaltet alle gloalen Variablen, die in den einhzelnen Fenstern festgelegt werden und als Wert für andere Programmfunktionen verwendet.
 * die Auswahlmenu Funktion wird als Hauptfenster bei der Ausführung aufgerufen
 * @todo eventuelle Auslagerug der while-schleifen als Steurungsfunktion für alle Fenster. Hierfür wird in erster Linie ein gutes Konzept zur Realisierung in C gebraucht.
*/

/// speichert Dateipfad hinter "Current File: " (Load Mnemonics)
char current_file[MAX_BUFFER_SIZE]; // modusFilechooser = 0
/// speichert Dateipfad hinter "Current Binary: " (Bootloader)
char current_binary[MAX_BUFFER_SIZE]; // modusFilechooser = 1
/// für filechooser(), bestimmt in welche Variable der Dateipfad gespeichert wird
int modusFilechooser; // welche File ausgewählt wird
/// für switch-cases
int c;
/// speichert Baudrate (Config Serial)
int baud;
/// speichert COMPort (Config Serial)
char comport_path[MAX_BUFFER_SIZE]="";

// file handle for config file
const char *config_file = "config.cfg";

// -------- global variables für uart --------
// uart port handle
int fd_uart;

// bootloader packet buffer
uint8_t packet_header;
uint16_t packet_data;
uint8_t packet_buf[3];
// read .bin file to transmit
char *mem_image;
off_t mem_size;

/**
 * Main der Host Applikation
*/
int main() {
    // ncurses initialisieren
    initscr();
    raw();
    keypad(stdscr, TRUE);
    noecho();
    // Fehlermeldung falls Farben nicht unterstützt werden
    if (has_colors() == FALSE) {
        endwin();
        printf("< [ err ] Terminal does not support colors! >");
    }

    start_color();
    init_color(COLOR_MATRIX_GREEN, 12, 628, 384); // Matrix Grün
    init_pair(1, COLOR_WHITE, COLOR_MATRIX_GREEN);  // Farben für Markierung
    auswahlmenu(); // Zu Programmstart befindet man sich im Auswahlmenü
}
