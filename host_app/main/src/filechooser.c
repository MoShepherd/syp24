#include <ncurses.h>
#include <stdlib.h>
#include <string.h>
#include "../includes/allefunktionen.h"

// in main.c deklarierte globale variablen
extern char* current_file; // modusFilechooser = 0
extern char* current_binary; // modusFilechooser = 1
extern int modusFilechooser; // welche File ausgewählt wird
extern int c; // fürs switch-case

/**
 * \brief filechooser(): Öffnet bei Aufruf den Dateimanager des Host PCs
 * 
 * Der Dateimanager des Host-PCs öffnet sich im Home-Verzeichnis und man kann eine beliebige Datei auswählen,
 * dessen Pfad dann dementsprechend (abhängig von der gewählten Option in der Applikation) anzeigt.
 * 
 * @todo Evtl. implementieren, dass bei "Load Mnemonics" nur .asm-Dateien und bei "Load Binary" nur .bin-Dateien ausgewählt werden können.
*/
void filechooser(){
    FILE* file;
    char buffer[MAX_BUFFER_SIZE];

    file = popen("zenity --file-selection --filename=$HOME/ms3/", "r"); // öffnet Dateimanager im Home-Verzeichnis, read-only

    if (file == NULL) {
        fprintf(stderr, "Error opening pipe.\n");
        return;
    }

    switch(modusFilechooser){ // welche Variable beschrieben wird bzw. welche Option gewählt wurde
        case 0: // Current File (Load Mnemonics)
            if (fgets(buffer, MAX_BUFFER_SIZE, file) != NULL) {
                size_t len = strlen(buffer);
                if (len > 0 && buffer[len - 1] == '\n') {
                    buffer[len - 1] = '\0';
                }
                free(current_file);
                current_file = strdup(buffer);
            }
            break;

        case 1: // Current Binary (Load Binary)
            if (fgets(buffer, MAX_BUFFER_SIZE, file) != NULL) {
                size_t len = strlen(buffer);
                if (len > 0 && buffer[len - 1] == '\n') {
                    buffer[len - 1] = '\0';
                }
                free(current_binary);
                current_binary = strdup(buffer);
            }
            break;
    }
    pclose(file);
}