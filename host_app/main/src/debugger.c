#include <ncurses.h>
#include <stdlib.h>
#include <string.h>
#include "../includes/allefunktionen.h"
#include "../includes/breakpointmanager.h"
#include <errno.h>
#include <limits.h>

// in main.c deklarierte globale variablen
extern char* selected_file;
extern char* current_file; // modusFilechooser = 0
extern char* current_binary; // modusFilechooser = 1
extern int modusFilechooser; // welche File ausgewählt wird
extern int c; // fürs switch-case

// Debugger globale Variablen
WINDOW *editorWindow;
extern int y_offset; // Offset
int breakpointActive = 1;

int breakpointNum = 0;

/**
 * \brief debugger(): Öffnet im Terminal ein neues Fenster mit Debugger Funktionen.
 *
 * Durch diese Funktion wird dem Nutzer die zuvor ausgewählte Datei angezeigt, mit welcher der Nutzer auch interagieren kann.
 * Dem Nutzer werden Optionen angezeigt womit markierungen an den jeweiligen Stellen in der Textdatei auftauchen.
 * Durch eine switch-case Anweisung werden verschiedene Optionen zur Interaktion mit dem Programmcode ermöglicht.
 *
 * @todo Breakpoints müssen noch an den FPGA übertragen werden.
 * @todo Single Steps fehlen komplett.
 * @todo Read RAM fehlt.
 * @todo Continue fehlt.
 * @todo Read Register öffnet ein neues Fenster jedoch fehlt der Inhalt komplett.
 * @todo Write Register fehlt.
 * @todo Es gibt einige Bugs die auftreten wenn zu oft 'Esc' und 'Q' gedrückt wird.
 *
*/
void debugger(){
    //DATEI datei;
    //wrefresh(curscr);
    int height, width;
    getmaxyx(stdscr, height, width);
    int current_line = 0; // Aktuelle Zeile der Textdatei
    int text_height = height / 1.5; // Setzen Sie die Textbox-Höhe
    editorWindow = newwin(text_height, width, 1, 5);
    scrollok(editorWindow, TRUE);
    keypad(editorWindow, TRUE);

    int modusDebugger; // Optionen = 0, Editor = 1
    int x, y; // Koordinaten Editor
    int i;
    int eStart, eEnde;

    const char *options = "(b) set BP - (d) Delete BP - (e) Single step - (r) Read RAM - (w) Write RAM - (c) Continue - (f) Read Register - (s) Write Register - (q) Quit Debugger"; //  - (F5) Editor / options mode
    char breakpoint[4]; // für Eingabe der Adresse
    unsigned long long breakpointLong; // für Konvertierung

    char status[MAX_BUFFER_SIZE * 2];
    strcpy(status, "Breakpoints:");

    char breakpoints[MAX_BUFFER_SIZE * 2];


    int hStart = height - height / 5; // Optionen Start vertikal
    int hEnd = hStart - 1; // Editor max y

    editorWindow = newwin(hEnd, width, 0, 0); // Editor Window

    getyx(editorWindow, y, x);


    int ff = 0;
    Breakpoint *bp = NULL;

    refresh();
    wrefresh(editorWindow);

    modusDebugger = 0;


    updateStatus(status);
    do{
        updateStatus(status);
            switch (c) {
                    case KEY_UP:
                        if (current_line > 0) current_line--;
                        updateStatus(status);
                        break;
                    case KEY_DOWN:
                        if (current_line < countLines(current_file) - text_height) current_line++;
                        updateStatus(status);
                        break;
                    case 98: // (b) BP setzen
                        if(breakpointActive == 0){
                            breakpointActive = 1;
                            break;
                        }
                        prompt_string("Address: ", breakpoint, 3);
                        if (checkHex(breakpoint)==0){
                            char prompt_message[25];
                            strcpy(prompt_message, " Set breakpoint at ");
                            strcat(prompt_message, breakpoint);
                            strcat(prompt_message, "? ");

                            if(prompt_yesno(prompt_message) == 0){
                                breakpointLong = strtoul(breakpoint, NULL, 16);                           
                                addBreakpoint(&bp, breakpointLong);
                                breakpointNum++;                       
                                if(ff == 0){                                
                                    strcat(status, " ");
                                    char *blabla = strcat(status, breakpoint);
                                    strcpy(status, blabla);
                                    refresh();
                                    updateStatus(status);
                                    ff = 1;
                                } else {
                                    strcat(status, ", ");
                                    char *blabla = strcat(status, breakpoint);
                                    strcpy(status, blabla);
                                    refresh();
                                    updateStatus(status);
                                }
                            }
                            break;
                        }
                        break;
                        
                    case 100: // (d) BP löschen
                        prompt_string("Address: ", breakpoint, 3);

                        char prompt_message2[30];
                        strcpy(prompt_message2, " Delete breakpoint at ");
                        strcat(prompt_message2, breakpoint);
                        strcat(prompt_message2, "? ");
 
                        if(prompt_yesno(prompt_message2) == 0){
                            breakpointLong = strtol(breakpoint, NULL, 16);
                            removeBreakpoint(&bp, breakpointLong);
                            breakpointNum--;
                            refresh();
                            char temp[MAX_BUFFER_SIZE * 2];
                            getBreakpoints(&bp, &temp, sizeof(temp));
                            strcpy(status, "Breakpoints: ");
                            strcat(status, temp);
                            
                            //strcat(status, getBreakpoints(&bp,&temp,MAX_BUFFER_SIZE*2 ));
                            //delMarkedLine(editorWindow, current_file, current_line, text_height, breakpoint);

                            // An FPGA weiterleiten
                            // wenn an FPGA erfolgreich, aus Statusleiste / Liste löschen
                        }                
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
                        //} else {
                        readRegister(hStart, 0);
                        //}
                        break;
                    case 115: // (s) Write Register
                        //if(){ // nicht im CPU-Halt
                        //    mvprintw(hStart+1, wStart, "< [!] ERROR: CPU muss angehalten sein! >");
                        //}
                        break;
                    case 113: // (q) Quit Debugger
                        delList(&bp);
                        clear();
                        auswahlmenu();
                        break;
                    /*
                    case KEY_F(5): // (F5) Editor / options mode
                        modusDebugger = 1;
                        break;
                    */
            }
            int new_height, new_width;
            getmaxyx(stdscr, new_height, new_width);
    
            // Prüfen, ob eine Größenänderung stattgefunden hat
            if (new_height != height || new_width != width) {
                // Resizing vom Terminal
                delwin(editorWindow);
                clear();
                refresh();
                text_height = new_height / 1.5;
                editorWindow = newwin(text_height, new_width, 1, 5);
                scrollok(editorWindow, TRUE);
                keypad(editorWindow, TRUE);
                box(editorWindow, 0, 0); // Eine Box um das Fenster zeichnen
                height = new_height;
                width = new_width;
            }
            //printBPs(&bp, status, breakpointNum);
            updateStatus(status);
            
            werase(editorWindow);
            printFile(editorWindow, current_file, current_line, text_height, &bp);
            wrefresh(editorWindow);

            mvhline(height/1.3, 0, '=', width);
            mvprintw(height/ 1.2, 5, "%s", options);
            refresh();
    } while((c = getch()) != 27 || (c = getch() != 113));
    clear();
}

/**
 * \brief printBPs(Breakpoint** top, char status[], int breakpointNum): gibt die Breakpoints in der Statusleiste aus.
 *
 * Durch diese Funktion wird unten Links die Statusleiste aktualisiert.
 *
 * @todo Funktion wird nicht verwendet!
 *
*/
void printBPs(Breakpoint** top, char status[], int breakpointNum){
    
    Breakpoint *tmp = NULL;
    char str_addr[5];
mvprintw(1,0,"otto");
        refresh();
    for(int i = 0; i < breakpointNum; i++){
        tmp = getBreakpoint(top, 0);
        
        if(tmp != NULL){
            sprintf(str_addr,"%03x",tmp->hexAddress);           
            strcat(status, str_addr);
        }
            
    }

}

/**
 * \brief printXY(int x, int y): gibt die Position des Cursors im editorWindow an.
 *
 * Durch diese Funktion wird einem angezeigt wo sich der Cursor im editorWindow befindet.
 *
 * @todo Funktion diente eigentlich für einen Texteditor im Debugger Fenster, welcher verworfen wurde. Methode wird nicht verwendet!
 *
*/
void printXY(int x, int y){
    int oldx, oldy;
    getyx(editorWindow, y, x);
    mvprintw(0, COLS - 20, "x: %d y: %d o: %d", x, y, y_offset);
    move(oldy, oldx);
}

/**
 * \brief printFile(WINDOW *win, const char *filename, int start_line, int num_lines, Breakpoint** top): schreibt den Inhalt des übergebenen Dateinamen in das Debugger Fenster.
 *
 * Durch diese Funktion wird einem die Datei angezeigt die zuvor gewählt wurde.
 * Hierzu wird für jede Zeile geschaut ob es sich um eine Breakpoint Zeile handelt.
 * Sollte das der Fall sein wird sie mit einem '*' gekennzeichnet.
 *
 * @param win Das Fenster in welchem die Datei angezeigt werden soll.
 * @param filename Dateipfad zu der Datei die angezeigt werden soll.
 * @param start_line Zeile in der die Datei starten soll angezeigt zu werden (Fensterformatierung).
 * @param num_linesAnzahl der Zeilen in der Datei.
 * @param top Kopfelement der verketteten Liste.
*/
void printFile(WINDOW *win, const char *filename, int start_line, int num_lines, Breakpoint** top){
    FILE *f;
    f = fopen(filename, "r");
    
    char line[256];
    char lineTok[256];
    int currentLine = 0;

    while(fgets(line, sizeof(line), f) != NULL){
        Breakpoint *current = *top;

        strcpy(lineTok, line);
        char *tok = strtok(lineTok, ":");
        unsigned long long hexTok = strtoul(tok, NULL, 16);

        if(currentLine >= start_line && currentLine < start_line + num_lines) {
            int isBP = 0;

            while(current != NULL){
                if(hexTok == current->hexAddress){
                    isBP = 1;
                    break;
                }
                current = current->next;
            }

            wmove(win, currentLine - start_line, 0);
            if(isBP){
                wprintw(win, "*");
            } else {
                wprintw(win, " ");
            }

            wmove(win, currentLine - start_line, 2);
            wprintw(win, "%s", line);

        }
        currentLine++;
    }
    fclose(f);
}

/**
 * \brief markLine(WINDOW *win, const char *filename, int start_line, int num_lines, char *adr): markiert eine bestimmte Zeile mit einem '*'.
 *
 * Durch diese Funktion wird einem die Breakpoint-Zeilen angezeigt.
 *
 * @todo Funktion wird nicht verwendet!
 *
*/
void markLine(WINDOW *win, const char *filename, int start_line, int num_lines, char *adr){
    FILE *f;
    f = fopen(filename, "r");

    char line[256];
    int currentLine = 0;

    while(fgets(line, sizeof(line), f) != NULL){
        char *tok = strtok(line, ":");
        if(currentLine >= start_line && currentLine < start_line + num_lines) {
            if(strcmp(tok, adr) == 0){
                wmove(win, currentLine - start_line, 0);
                wprintw(win, "*");
                refresh();
                wrefresh(win);
            }
            currentLine++;
        }
    }
    fclose(f);
}

/**
 * \brief delMarkedLine(WINDOW *win, const char *filename, int start_line, int num_lines, char *adr): hebt '*'-Markierung auf.
 *
 * Durch diese Funktion wird der '*' vor einer Zeile gelöscht.
 *
 * @todo Funktion wird nicht verwendet!
 *
*/
void delMarkedLine(WINDOW *win, const char *filename, int start_line, int num_lines, char *adr){
    FILE *f;
    f = fopen(filename, "r");

    char line[256];
    int currentLine = 0;

    while(fgets(line, sizeof(line), f) != NULL){
        char *tok = strtok(line, ":");
        if(currentLine >= start_line && currentLine < start_line + num_lines) {
            if(strcmp(tok, adr) == 0){
                wmove(win, currentLine - start_line, 0);
                wprintw(win, " ");
                refresh();
                wrefresh(editorWindow);
            }
            currentLine++;
        }
    }
    fclose(f);
}

/**
 * \brief highlightLine(WINDOW *win, const char *filename, int start_line, int num_lines, char *adr): markiert eine Zeile.
 *
 * Durch diese Funktion wird eine Zeile markiert.
 *
 * @todo Funktion wird nicht verwendet! Jedoch soll sie dazu dienen die Stelle anzuzeigen an welcher das Programm stehen geblieben ist (Breakpoints, Single Steps).
 *
*/
void highlightLine(WINDOW *win, const char *filename, int start_line, int num_lines, char *adr){
    FILE *f;
    f = fopen(filename, "r");

    char line[256];
    int currentLine = 0;
   
    while(fgets(line, sizeof(line), f) != NULL){
        char *tok = strtoul(tok, NULL, 16); // Adresse in unsigned long long
        if(currentLine >= start_line && currentLine < start_line + num_lines) {
            if(adr == tok){
                attron(COLOR_PAIR(1));
                mvprintw(currentLine, sizeof(line), "%s", line);
                attroff(COLOR_PAIR(1));
                refresh();
                wrefresh(win);
            }
            currentLine++;
        }
    }
    fclose(f);
}

/**
 * \brief countLines(const char *filename): zählt die Zeilen in der übergebenen Datei.
 *
 * Durch diese Funktion wird eine Zeile markiert.
 *
 * @todo Funktion wird nicht verwendet! Jedoch soll sie dazu dienen die Stelle anzuzeigen an welcher das Programm stehen geblieben ist (Breakpoints, Single Steps).
 *
*/
int countLines(const char *filename) {
    FILE *f = fopen(filename, "r");
    int lines = 0;
    char buffer[MAX_BUFFER_SIZE];

    while (fgets(buffer, sizeof(buffer), f)) {
        lines++;
    }

    fclose(f); // Schließt die Datei
    return lines; // Gibt die Anzahl der Zeilen zurück
}

/**
 * \brief checkHex(const char *str): überprüft ob ein übergebener String einen gültigen HExwert enthält
 *
 * @param str String welcher auf Hexwert geprüft werden soll
 *
*/
int checkHex(const char *str) {
    char *end;
    long int num;

    errno = 0;    // Setzt errno auf 0 vor dem Aufruf
    num = strtol(str, &end, 16);  // Konvertiert String zu long int im Hexadezimalformat

    // Überprüft, ob keine Zahlen im String enthalten sind
    if (end == str) {
        return 2;  // Keine Ziffern gefunden
    }

    // Überprüft, ob der String vollständig verarbeitet wurde
    if (*end != '\0') {
        return 2;  // String enthält ungültige Zeichen
    }

    // Überprüft auf Überlauf oder Unterlauf
    if (errno == ERANGE && (num == LONG_MAX || num == LONG_MIN)) {
        return 1;  // Wert ist außerhalb des gültigen Bereichs
    }

    // Überprüft, ob der Wert im zulässigen Bereich liegt
    if (num < 0 || num > 0x3FF) {
        return 1;  // Wert außerhalb des Bereichs
    }

    return 0;  // Gültige Hexadezimalzahl im Bereich
}

/**
 * \brief readRegister(int y, int x): Öffnet im Terminal ein neues Fenster.
 *
 * Durch diese Funktion wird dem Nutzer die Möglichkeit geboten die verschiedenen Register des FPGAs auszulesen.
 *
 * @todo Keine der Auswahlmöglichkeiten außer 'b' funktionieren.
 *
 * @param x x-Koordinate wo die Register angezeigt werden sollen.
 * @param y y-Koordinate wo die Register angezeigt werden sollen.
*/
void readRegister(int y, int x){
    int height, width;
    getmaxyx(stdscr, height, width);
    int hStart = height / 8;
    int wStart = (width - 12) / 10;
    const char *wert;
    wert = "";

    breakpointActive = 0;
    const char *optionsRegister = "(1) Get program counter - (2) Get instruction register - (3) Get auxiliary register - (4) Get accumulator - (5) Get status register - (b) Back";

    while ((c = getch()) != 98){
        clear();
        for(int n = 0; n < width; n++) mvprintw(((height - height / 5) - 1), n, "="); // Trenner oben
        mvprintw(y, x, optionsRegister); // y = hStart, x = 0
        refresh();
        switch(c){
            case 49: // (1) Get program counter
                mvprintw(hStart, wStart + 3, "- Program Counter Info -"); // Programmzähler
                //wert = ;
                mvprintw(hStart + 3, wStart, "Program Counter: %s", wert);
                break;
            case 50: // (2) Get instruction register
                mvprintw(hStart, wStart, "- Instruction Register Info -"); // Befehlsregister
                //wert = ;
                mvprintw(hStart + 3, wStart, "Instruction Register: %s", wert);
                break;
            case 51: // (3) Get auxiliary register 
                mvprintw(hStart, wStart + 1, "- Auxiliary Register Info -"); // Hilfsregister
                //wert = ;
                mvprintw(hStart + 3, wStart, "Auxiliary Register: %s", wert);
                break;
            case 52: // (4) Get accumulator
                mvprintw(hStart, wStart + 4, "- Accumulator Info -"); // Akkumulator
                //wert = ;
                mvprintw(hStart + 3, wStart, "Accumulator: %s", wert);
                break;
            case 53: // (5) Get status register
                mvprintw(hStart, wStart + 3, "- Status Register Info -"); // Status Register
                // wert = ;
                mvprintw(hStart + 3, wStart, "Status Register: %s", wert);
                break;
            case 98: // (b) Back -> Debugger-Optionen wieder anzeigen
                clear();
                // gerade werden noch die Werte der Breakpoints-Anzeige mitgelöscht, weil die unabhängig von der Liste für den FPGA sind
                break;
        }
        
    }
    debugger();   
}