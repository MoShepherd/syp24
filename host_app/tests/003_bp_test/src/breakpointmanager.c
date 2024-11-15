#include "../includes/breakpointmanager.h"

int addBreakpoint(Breakpoint** top, unsigned long long address){
    Breakpoint* newBreakpoint = (Breakpoint*)malloc(sizeof(Breakpoint));

    if(newBreakpoint == NULL){
        return 1; // Breakpoint konnte nicht auf host_app gespeichert werden
    }

    newBreakpoint->hexAddress = address;
    newBreakpoint->next = NULL;

    if(*top == NULL){
        *top = newBreakpoint;
        return 0; // Breakpoint ist Kopf der Liste (erstes Objekt)
    }

    Breakpoint* current = *top;
    while(current->next != NULL){
        current = current->next;
    }

    current->next = newBreakpoint;
    return 0; // Breakpoit wurde an das Ende der Liste hinzugef�gt
}

int removeBreakpoint(Breakpoint** top, unsigned long long address){
    if(*top == NULL){
        return 2; // Liste ist leer
    }

    if((*top)->hexAddress == address){
        Breakpoint* tmp = *top;
        *top = (*top)->next;
        free(tmp);
        return 0; // Breakpoint wurde gel�scht (erstes Objekt in der Liste)
    }

    Breakpoint* current = *top;
    Breakpoint* prev = NULL;

    while(current != NULL && current->hexAddress != address){
        prev = current;
        current = current->next;
    }

    if(current != NULL){
        prev->next = current->next;
        free(current);
        return 0; // Breakpoint wurde gel�scht (Liste wurde aufgef�llt)
    }
    return 1; // Breakpoint wurde nicht gefunden (nicht in der Liste)
}

/*void printBreakpoints(Breakpoint* top, int y, int x){
    Breakpoint* current = top;
    while(current != NULL){
        mvprintw(y, x, "%llx", current->hexAddress);
        current = current->next;
    }
}
*/

/*void markBreakpoints(WINDOW *win, const char *filename, int start_line, int num_lines, Breakpoint *breakpoints) {
    FILE *f;
    f = fopen(filename, "r");

    char line[256];
    int currentLine = 0;

    while (fgets(line, sizeof(line), f) != NULL) {
        char *tok = strtok(line, ":");

        if (currentLine >= start_line && currentLine < start_line + num_lines) {
            unsigned long long currentAddress;
            sscanf(tok, "%llx", &currentAddress);

            Breakpoint *currentBreakpoint = breakpoints;
            while (currentBreakpoint != NULL) {
                if (currentBreakpoint->hexAddress == currentAddress) {
                    wmove(win, currentLine - start_line, 0);
                    wprintw(win, "*");
                    refresh();
                    wrefresh(win);
                    break;  
                }
                currentBreakpoint = currentBreakpoint->next;
            }

            currentLine++;
        }
    }

    fclose(f);
}
*/

void delList(Breakpoint** top) {
    Breakpoint* current = *top;
    Breakpoint* next;

    while (current != NULL) {
        next = current->next;
        free(current);
        current = next;
    }

    *top = NULL;
}

void printf_breakpoints(Breakpoint* top){
    Breakpoint* current = top;
    while(current != NULL){
		printf("%llx\n", current->hexAddress);
        current = current->next;
    }
	printf("\n");
}

void getBreakpoints(Breakpoint** top, char *ret, size_t retSize) {
    Breakpoint* current = *top;
    ret[0] = '\0'; // Initialisiert als leerer String

    while (current != NULL) {
        // Prüft, ob genügend Platz für den nächsten Breakpoint und das Komma vorhanden ist
        if (strlen(ret) + strlen(current->hexAddress) + 2 < retSize) {
            strcat(ret, current->hexAddress);
            if (current->next != NULL) {
                strcat(ret, ", ");
            }
        } else {
            // Nicht genügend Platz, bricht die Schleife ab
            break;
        }
        current = current->next;
    }
}
