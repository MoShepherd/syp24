#include "../includes/breakpointmanager.h"
#include <string.h>

/**
 * \brief addBreakpoint(Breakpoint** top, unsigned long long address): fügt einen neuen Breakpoint an die verkettete Liste.
 *
 * Im Parameter wird der Kopf der verketteten Liste und die Adresse an welcher der neue Breakpoint gesetzt wurde übergeben.
 * Es wird dann bis zum letztem Objekt der verketteten Liste iteriert und an daran ein neuer Breakpoint gesetzt, welcher als Adresse den im Parameter übergebenen Wert erhält.
 *
 * @param top Das Kopfelement der verketteten Liste.
 * @param address Adresse an der ein Breakpoint gesetzt werden soll.
 * @return Gibt durch eine Zahl 1, 2 oder 0 an ob der Breakpoint an die verkettete Liste gehangen wurde oder nicht.
*/
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

/**
 * \brief removeBreakpoint(Breakpoint** top, unsigned long long address): löscht einen Breakpoint aus der verketteten Liste.
 *
 * Im Parameter wird der Kopf der verketteten Liste und die Adresse welche aus der verketteten Liste gelöscht werden soll übergeben.
 * Es wird dann bis zum letztem Objekt der verketteten Liste iteriert und die übergebene Adresse aus der verketteten Liste gelöscht.
 *
 * @param top Das Kopfelement der verketteten Liste.
 * @param address Adresse von welcher ein Breakpoint gelöscht werden soll.
 * @return Gibt durch eine Zahl 1, 2 oder 0 an ob der Breakpoint aus der verkettete Liste gelöscht wurde oder nicht.
*/
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

/**
 * \brief getBreakpoints(Breakpoint** top, char* ret, size_t retSize): schreibt die Breakpoints in die übergebene ret Variable.
 *
 * Im Parameter wird der Kopf der verketteten Liste und das String an welches die Breakpoint Adressen angehangen werden sollen übergeben.
 *
 * @param top Das Kopfelement der verketteten Liste.
 * @param ret String an welches die Adressen der Breakpoints in der verketteten Liste angehangen werden sollen.
*/
void getBreakpoints(Breakpoint** top, char* ret, size_t retSize) {
    Breakpoint* current = *top;
    ret[0] = '\0'; // Initialisiert als leerer String
    char formattedAddress[10]; // Angenommen, die Adresse passt in diese Größe

    while (current != NULL) {
        sprintf(formattedAddress, "%03x", current->hexAddress);

        // Prüft, ob genügend Platz für den nächsten Breakpoint und das Komma vorhanden ist
        if (strlen(ret) + strlen(formattedAddress) + 2 < retSize) {
            strcat(ret, formattedAddress);
            if (current->next != NULL) {
                strcat(ret, ", ");
            }
        } else {
            break; // Nicht genügend Platz, bricht die Schleife ab
        }
        current = current->next;
    }
}

/**
 * \brief getBreakpoint(Breakpoint** top, int index): gibt einen bestimmten Breakpoint in der Liste zurück.
 *
 * Im Parameter wird der Kopf der verketteten Liste und der Index übergeben.
 * Es wird dann bis zum Index durch die Liste iteriert und der Breakpoint an der Stelle von Index zurückgegeben.
 *
 * @param top Das Kopfelement der verketteten Liste.
 * @param index Das wie vielte Objekt in der verketteten Liste ausgegeben werden soll.
 * @return gibt einen Pointer auf den Breakpoint zurück.
*/
Breakpoint* getBreakpoint(Breakpoint** top, int index){
    Breakpoint* current = *top;

    int i = 0;

    while(current != NULL){
        while(i < index){
            current = current->next;
        }
    }
    return current;
}

/**
 * \brief markBreakpoints(WINDOW *win, const char *filename, int start_line, int num_lines, Breakpoint *breakpoints): markiert die Breakpoints
 *
 * @todo Diese Funktion funktioniert nicht und wird auch nicht gebraucht im Moment. Kann also gelöscht werden!
*/
void markBreakpoints(WINDOW *win, const char *filename, int start_line, int num_lines, Breakpoint *breakpoints) {
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

/**
 * \brief delList(Breakpoint** top): löscht die verketteten Liste.
 *
 * Im Parameter wird der Kopf der verketteten Liste, welche gelöscht werden soll übergeben.
 *
 * @param top Das Kopfelement der verketteten Liste.
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