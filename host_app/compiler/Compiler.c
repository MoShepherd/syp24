#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

/**
 * \brief Datenstruktur, die das 3 Byte große Datenpaket abbildet.
*/
typedef struct cmd {
    unsigned char pakettyp;
    unsigned char opCode;
    unsigned char adr;
} cmd;

/**
 * \brief Mapping um zu Mnemonic korrespondierenden Opcode zu finden und andersrum.
*/
const char * mnemonicMappings[][2] = {
        {"NoOp", "0x10"},
        {"LDM", "0x11"},
        {"XOR", "0x37"},
        {"LDI", "0x12"},
        {"LDA", "0x18"},
        {"STI", "0x21"},
        {"STM", "0x28"},
        {"ADD", "0x30"},
        {"SUB", "0x31"},
        {"MUL", "0x32"},
        {"DIV", "0x33"},
        {"AND", "0x34"},
        {"OR", "0x35"},
        {"NOT", "0x36"},
        {"INC", "0x38"},
        {"DEC", "0x39"},
        {"LEFT", "0x3C"},
        {"RIGHT", "0x3D"},
        {"JM", "0x41"},
        {"JA", "0x48"},
        {"JZM", "0x51"},
        {"JNM", "0x52"},
        {"JLM", "0x53"},
        {"JZA", "0x58"},
        {"JNA", "0x59"},
        {"JLA", "0x5A"},
        {"IN", "0x61"},
        {"OUT", "0x71"},
};

/**
 * \brief Mapping um zu Opcode korrespondierende Mnemonic zu finden und andersrum.
 * @todo kann weggelassen werden, wenn man bin2mnem(char* filename) zuvor bearbeitet.
*/
const char * binaryMappings[][2] = {
    {"0x10", "NoOp"},
    {"0x11", "LDM"},
    {"0x12", "LDI"},
    {"0x18", "LDA"},
    {"0x21", "STI"},
    {"0x28", "STM"},
    {"0x30", "ADD"},
    {"0x31", "SUB"},
    {"0x32", "MUL"},
    {"0x33", "DIV"},
    {"0x34", "AND"},
    {"0x35", "OR"},
    {"0x36", "NOT"},
    {"0x37", "XOR"},
    {"0x38", "INC"},
    {"0x39", "DEC"},
    {"0x3C", "LEFT"},
    {"0x3D", "RIGHT"},
    {"0x41", "JM"},
    {"0x48", "JA"},
    {"0x51", "JZM"},
    {"0x52", "JNM"},
    {"0x53", "JLM"},
    {"0x58", "JZA"},
    {"0x59", "JNA"},
    {"0x5A", "JLA"},
    {"0x61", "IN"},
    {"0x71", "OUT"},
};

/**
 * \brief mnem2bin(char* filename): erstellt eine neue .bin Datei aus einer Textdatei die mit Assembler Mnemonics befüllt ist.
 * 
 * Im Parameter wird ein Dateipfad zu einer Datei angegeben. Diese wird geöffnet und gelesen.
 * Anhand des Inhaltes werden die Positionen in dem Array des Typen cmd, der Opcode und die Adresse ermittelt.
 * Zuvor wird das gesamte Array mit dem Pakettypen 0x02 und 0x00 0x00 gefüllt.
 * Dann wird in einem Mapping nach zu dem Mnemonic korrespondierenden Opcodes gesucht.
 * Sollte diese gefunden werden, werden diese in dem Array mit der Adresse gespeichert.
 * Darauf folgt das Speichern des erstellten Arrays in eine .bin Datei.
 *
 * @todo Adressen direkt beschreiben ohne Opcode.
 * 
 * @param filename Pfad zu einer Datei die Assembler-Mnemonics enthält und übersetzt werden soll.
 * @return Gibt durch eine Zahl 1 oder 0 an ob die übersetzte Binärdatei erstellt wurde.
*/
int mnem2bin(char* filename) {
    // Formattierung der Ursprungsdatei um besser auslesen zu können
    formatFile(filename);

    char formattedFilename[256];
    strncpy(formattedFilename, filename, sizeof(formattedFilename));
    strcat(formattedFilename, "_fmtd.txt");

    // Öffnen der .txt Datei mit dem Assemblercode
    FILE *asmfile;
    asmfile = fopen(formattedFilename, "r");

    // Variablen die später zur konvertierung in Hex genutzt werden
    unsigned long int uc_opcode, uc_address;

    // Endpointer der für konvertierung in Hex nötig ist
    char *endptr = NULL;

    // a ist der Zähler für die Anzahl an Commands in der Textdatei (zähl die Zeilen)
    int a = 0;

    // Error 1: Datei konnte nicht gefunden werden
    if (asmfile == NULL) {
        return 1;
    }

    char line[256];
    cmd commands[1024];

    // Vorbefüllen des Arrays mit dem Pakettypen (0x02) und den Werten 0 (0x00), da immer aufgefüllt werden soll
    for(int i=0; i < sizeof(commands) / sizeof(commands[0]); i++){
        commands[i].pakettyp = strtoul("0x02", &endptr, 16);
        commands[i].opCode = strtoul("0x00", &endptr, 16);
        commands[i].adr = strtoul("0x00", &endptr, 16);
    }

    // Lesen jeder Zeile
    while (fgets(line, sizeof(line), asmfile) != NULL) {
        char *tok = strtok(line, ":"); // Zeichen vor dem ':' wird tokenized damit die die Position in der Binärdatei festgestellt werden kann
        int pos = strtoul(tok, &endptr, 16);
        if (tok != NULL) {
            tok = strtok(NULL, "\t\n"); // Jedes Zeichen vor einem Zeilenumbruch wird tokenized um daraus Mnemonic Befehl und Adresse zu lesen
            if (tok != NULL) {
                // Suche nach Mnemonic in dem Mapping
                for (int i = 0; i < sizeof(mnemonicMappings) / sizeof(mnemonicMappings[0]); i++) {
                    // Wenn Mnemonic in Mapping gefunden werden konnte, wird der Binäre Partnerwert im Array an der Position pos im opCode gespeichert. Die letzten 2 Zeichen werden als adr gespeichert
                    if(strstr(tok, mnemonicMappings[i][0]) != NULL){
                        int len = strlen(tok);
                        const char *adrString = &tok[len-3];
                        char adrHex[10];
                        snprintf(adrHex, sizeof(adrHex), "0x%s", adrString);
                        // Umwandlung der Hex-Strings in Hex-hex
                        uc_address = strtoul(adrHex, &endptr, 16);
                        uc_opcode = strtoul(mnemonicMappings[i][1], &endptr, 16);
                        commands[pos].opCode = uc_opcode;
                        commands[pos].adr = uc_address;
                        a++;
                        break;
                    }
                }
            }
        }
    }

    // Binärdatei wird erstellt und mit den Werten im Array befüllt
    char outputFilename[256];
    strncpy(outputFilename, filename, sizeof(outputFilename));
    strcat(outputFilename, "_output.bin");

    FILE *binFile = fopen(outputFilename, "wb");
    fwrite(commands, sizeof(cmd), 1024, binFile);

    // Schließen der geöffneten Dateien
    fclose(asmfile);
    fclose(binFile);

    return 0;
}

/**
 * \brief bin2mnem(char* filename): erstellt eine neue .txt Datei aus einer Binärdatei die mit Opcode und Adresse befüllt ist.
 *
 * Im Parameter wird ein Dateipfad zu einer Datei angegeben. Diese wird geöffnet und gelesen.
 * Anhand des Inhaltes werden die Positionen in dem Array des Typen cmd, der Opcode und die Adresse ermittelt.
 * In einem Mapping wird nach zu dem Opcode korrespondierenden Mnemonics gesucht.
 * Sollten diese gefunden werden, werden diese in dem Array mit der Adresse gespeichert.
 * Darauf folgt das Speichern des erstellten Arrays in eine .txt Datei.
 *
 * @todo Im Moment gibt es zwei Mappings, wobei eins komplett ausreicht.
 * @todo Funktion funktioniert noch nicht richtig. Es werden noch nicht alle Opcodes ausgelesen und die Datei wird fehlerhaft erstellt.
 *
 * @param filename Pfad zu einer Binäratei die Opcodes enthält und übersetzt werden soll.
 * @return Gibt durch eine Zahl 1 oder 0 an ob die übersetzte Mnemonic-Datei erstellt wurde.
*/
int bin2mnem(char* filename){
    FILE *binFile;
    binFile = fopen(filename, "rb");
    FILE *mnemFile = fopen("testBin.txt", "w");
    int a = 0; // Zähler bis 4 (für einzelne Bits)
    int b = 0; //Zähler für Commands - wenn a == 4, b++, a = 0

    if(binFile == NULL){
        return 1; // Error 1: Datei konnte nicht gefunden werden
    }
    cmd commands[1024];
    size_t bytesRead = fread(commands, sizeof(cmd), 1024, binFile);

    for(size_t i = 0; i < bytesRead; i++){
        for(int j = 0; j < sizeof(binaryMappings) / sizeof(binaryMappings); j++){
            if(commands[i].opCode == binaryMappings[j][0]){
                fprintf(mnemFile, "%s:", binaryMappings[j][1]);
                printf("%02X\n", commands[i].opCode);
                break;
            } else {
                printf("OopCode: %x, binmap: %s\n", commands[i].opCode, binaryMappings[j][1]);
            }
        }

        fprintf(mnemFile, "%02X\n", commands[i].adr);
    }

    fclose(binFile);
    fclose(mnemFile);

    return 0;
}

/**
 * \brief formatFile(char* filename): bringt eine Datei mit Assembler-Mnemonics in ein bestimmtes Format damit der Compiler benötigte Daten besser auslesen kann.
 *
 * Im Parameter wird ein Dateipfad zu einer Datei angegeben. Diese wird geöffnet und gelesen.
 * Jede Zeile der im Parameter übergebenen Datei wird in eine neue Datei geschrieben.
 * Hierbei werden jedoch Leerzeilen, Leerzeichen sowie durch '#' oder ';' gekennzeichnete Kommentare entfernt.
 * Die Methode bringt die Datei in ein bestimmtes Format, damit der Compiler die Daten besser auslesen kann.
 *
 * @todo Im Moment wird noch eine neue Datei erstellt, was ineffizient ist. Stattdessen könnte man den formatierten Text in einem Buffer speichern und den darin stehenden Inhalt dann kompilieren.
 *
 * @param filename Pfad zu einer Datei die Assembler-Mnemonics enthält und übersetzt werden soll.
*/
void formatFile(char* filename) {
    // inputFile ist die Datei die zu formattieren ist. Diese wird formattiert in die Datei outputFile gespeichert
    FILE *inputFile = fopen(filename, "r");

    // outputFile bekommt die _fmtd.txt-Endung um zu zeigen dass dies die formatierte Datei ist
    char outputFilename[256];
    strncpy(outputFilename, filename, sizeof(outputFilename));
    strcat(outputFilename, "_fmtd.txt");

    FILE *outputFile = fopen(outputFilename, "w");

    if (inputFile == NULL || outputFile == NULL) {
        perror("Datei konnte nicht geöffnet werden!\n");
        return;
    }

    char line[256];
    while (fgets(line, sizeof(line), inputFile) != NULL) {
        // Kommentare die durch '#', ';' begonnen werden/beinhalten, werden bis zum letzten Zeichen der Zeile ignoriert
        char *hashPos = strchr(line, '#');
        char *semicolonPos = strchr(line, ';');
        if (hashPos != NULL) *hashPos = '\0';
        if (semicolonPos != NULL) *semicolonPos = '\0';

        // Leerzeichen, Tabulator und Zeilenumbrüche werden ignoriert
        char *start = line;
        while (*start == ' ' || *start == '\t' || *start == '\r' || *start == '\n') {
            start++;
        }

        char *end = line + strlen(line) - 1;
        while (end > start && (*end == ' ' || *end == '\t' || *end == '\n' || *end == '\r')) {
            end--;
        }
        *(end + 1) = '\0';

        // Zwischen Zeichen liegende Leerzeichen und Tabulatoren werden ebenfalls ignoriert
        char *src = start;
        char *dest = start;

        while (*src) {
            if (*src != ' ' && *src != '\t') {
                *dest = *src;
                dest++;
            }
            src++;
        }
        *dest = '\0';

        // Alle Zeichen im formattierten Format werden in der formattierten Datei gespeichert
        if (strlen(start) > 0) {
            fprintf(outputFile, "%s \n", start);
        }
    }

    fclose(inputFile);
    fclose(outputFile);
}
