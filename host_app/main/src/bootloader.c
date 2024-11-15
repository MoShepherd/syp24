#include <fcntl.h>
#include <ncurses.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../../uart/include/uart.h"
#include "../includes/allefunktionen.h"
#include "../includes/statusbar.h"

// in main.c deklarierte globale variablen
extern char* current_binary; // modusFilechooser = 1
extern int modusFilechooser; // welche File ausgewählt wird
extern int c;                // fürs switch-case

// extern uart globals
extern int fd_uart;
extern char *mem_image;
extern off_t mem_size;
extern uint8_t packet_header;
extern uint16_t packet_data;
extern uint8_t packet_buf[3];


/**
 * \brief bootloader(): Seite vom Menüpunkt "Bootloader" wird geöffnet.
 * 
 * Nach Aufruf werden im Terminal drei neue Optionen angezeigt, sowie eine ähnliche Anzeige,
 * die wie "Current File: " im Auswahlmenü den Dateipfad der Binärdatei anzeigt, die man über "Load Binary" auswählt.
 * 
 * @todo Execute wurde noch nicht implementiert.
*/

void bootloader() {
    wrefresh(curscr);
    int height, width;
    getmaxyx(stdscr, height, width);

    int wStart = (width - 12) / 10; // "widthStart"
    int hStart = height / 8; // "heightStart"

    int selectedRow = hStart;
    char *options[] = {"Current Binary: ", "(1) Load Binary", "(2) Execute", "(3) Upload to RAM", "> Back"}; // Optionen deklarieren

    // print selected binary file, if not NULL
    if (current_binary != NULL) {
        mvprintw(height / 8, wStart + 16, current_binary);
        int file_status = open_file(current_binary, &mem_image, &mem_size);
        if (file_status < 0) {
            exit(EXIT_FAILURE);
        }
        refresh();
    }

    // Auswahl markieren
    for (int i = 0; i < 5; ++i) {
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
    while ((c = getch()) != 27) { // Programm wird mit esc beendet
        switch (c) {
        case KEY_UP:
            if (selectedRow > 1) {
                --selectedRow;
            }
            break;
        case KEY_DOWN:
            if (selectedRow < 4) {
                ++selectedRow;
            }
            break;
        case 10: // Drücken der Enter-Taste
            if (selectedRow == 1) { // Load Binary
                modusFilechooser = 1;
                clear();
                endwin();
                filechooser();
                initscr();
                if (current_binary != NULL) {
                    mvprintw(height / 8, wStart + 16, current_binary);
                    int file_status = open_file(current_binary, &mem_image, &mem_size);
                    if (file_status < 0) {
                        // close(fd_uart);
                        exit(EXIT_FAILURE);
                    }
                } else {
                    printStatusLine("< [ err ] No file has been chosen! >");
                }
                refresh();

            } else if (selectedRow == 2) { // Execute

            } else if (selectedRow == 3) { // Upload to RAM
                uart_tx_bl_packet(fd_uart, BL_TYPE_CMD_HOST_PC, CMD_HOST_UPLOAD_RAM);
                uart_rx_bl_packet(fd_uart, packet_buf);
                // start transmission, if packet is acknowledged
                if (packet_buf[0] != 0x0) {
                    printStatusLine("< [ err ] Binary transmission packet was not valid! >");
                } else {
                    printStatusLine("< [!] Start image transmitssion >");
                    uint8_t err = tx_mem_image(fd_uart, mem_image, mem_size);
                    // get status after transmitting the image;
                    uart_tx_bl_packet(fd_uart, BL_TYPE_CMD_HOST_PC, CMD_HOST_STATUS_QUERY);
                    uart_rx_bl_packet(fd_uart, packet_buf);

                    // error Auswertung
                    if (packet_buf[0] == BL_TYPE_ERR) {
                        packet_data |= packet_buf[1] << 8;
                        packet_data |= packet_buf[2];
                        if (packet_data == ERR_BUSY)
                            printf("[ err ] Memory transmission in progress: Another operation is currently being executed.");
                        if (packet_data == ERR_TRANS_INCOMPLETE)
                            printf("[ err ] Memory image transmission incomplete: The transmission was interrupted or not fully completed.");
                        if (packet_data == ERR_TRANS_OVERFLOW)
                            printf("[ err ] Memory image overflow: The transmitted image is too large for the available RAM.");
                        if (packet_data == ERR_TRANS_NOT_STARTED)
                            printf("[ err ] Memory transmission has not started yet!");
                        
                    } if (packet_buf[0] == BL_TYPE_ACK){
                        if (packet_data == STAT_TRANS_COMPLETE)
                            printStatusLine("[ STA ] Awaiting new Commands.");
                        //if (packet_data == STAT_TRANS_COMPLETE)
                            printStatusLine("[ STA ] Image successfully transmitted!");
                    }
                }
            } else if (selectedRow == 4) { // Back
                clear();
                auswahlmenu();
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
        for (int i = 0; i <= 4; ++i) {
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