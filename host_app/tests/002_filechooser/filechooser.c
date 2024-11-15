#include <ncurses.h>
#include <stdlib.h>
#include <string.h>

#define MAX_BUFFER_SIZE 1024

// in main.c deklarierte globale variablen
extern char* selected_file;
extern char* current_file; // modusFilechooser = 0
extern char* current_binary; // modusFilechooser = 1

extern int modusFilechooser; // welche File ausgewählt wird
extern int c; // fürs switch-case

void filechooser(){
    FILE* file;
    char buffer[MAX_BUFFER_SIZE];

    file = popen("zenity --file-selection --filename=$HOME/user", "r");

    if (file == NULL) {
        fprintf(stderr, "Error opening pipe.\n");
        return;
    }

    switch(modusFilechooser){
        case 0: // Current File
            if (fgets(buffer, MAX_BUFFER_SIZE, file) != NULL) {
                size_t len = strlen(buffer);
                if (len > 0 && buffer[len - 1] == '\n') {
                    buffer[len - 1] = '\0';
                }
                free(current_file);
                current_file = strdup(buffer);
            }
            break;

        case 1: // Current Binary
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
