#include <ncurses.h>
#include <stdlib.h>
#include <string.h>

#define MAX_BUFFER_SIZE 1024

// in main.c deklarierte globale variablen
char* selected_file;
char* current_file; // modusFilechooser = 0
char* current_binary; // modusFilechooser = 1
int modusFilechooser = 1; // welche File ausgewählt wird
int c; // fürs switch-case

char* filechooser(){
    FILE* file;
    char buffer[MAX_BUFFER_SIZE];

    file = popen("zenity --file-selection --filename=$HOME/user", "r");

    if (file == NULL) {
        fprintf(stderr, "Error opening pipe.\n");
        return NULL;
    }
    char *path;
    if (fgets(buffer, MAX_BUFFER_SIZE, file) != NULL) {
        size_t len = strlen(buffer);
        if (len > 0 && buffer[len - 1] == '\n') {
            buffer[len - 1] = '\0';
        }
        if (modusFilechooser == 0){
            free(current_file);
            current_file = strdup(buffer);
        }
        else if(modusFilechooser == 1){
            free(current_binary);
            current_binary = strdup(buffer);
        }
    }
    pclose(file);
    printf(current_binary);
}

int main() {
    filechooser();
}

