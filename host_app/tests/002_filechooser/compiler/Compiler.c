#include "Compiler.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <fcntl.h>

/*
typedef struct cmd {
    unsigned char pakettyp;
    unsigned char opCode;
    unsigned char adr;
} cmd; */

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
/*
int main(int argc, char *argv[]) {
    /*
    FILE *fp;
    typedef struct befehl{
        unsigned char opcode;
        unsigned char address;
    } befehl; 

    //unsigned char a[2048] = {0x10,0x00, 0x11,0x01, 0x12,0x02, 0x18,0x03};

    befehl b[1024];
    b[0].opcode  = 0x10;
    b[0].address = 0x00;
    b[1].opcode = 0x11;
    b[1].address = 0x01;
    b[2].opcode = 0x12;
    b[2].address = 0x02;

    uint16_t  a[2048] = {0x1000, 0x1101, 0x1202, 0x1803};
    fp = fopen("test.bin","wb");
    //fprintf(fp, "%s %s %s %d", "We", "are", "in", 2012);

    
    //buffer	-	pointer to the first object in the array to be written
    //size	-	size of each object
    //count	-	the number of the objects to be written
    //stream	-	pointer to the output stream

    //fwrite(<Array, was in Datei geschrieben werden soll>, <Wertepaare>, <Anzahl der Zeilen in Ursprungsfile>, <Pointer auf Ursprungsfile>);
    //fwrite(b, 2, 4, fp);
    //fprintf(fp, "%x", 1000); */
    
    //printf("blabalblablablablablb\n");
    
    /*
    if (argc < 2) {
        printf("Usage: %s <string1> <string2> ... <stringN>\n", argv[0]);
        return 1;  // Return an error code
    }

    // Display each command-line argument using printf
    for (int i = 1; i < argc; ++i) {
        printf("%s\n", argv[i]);
    }*/
/*
    mnem2bin(argv[1]);
    //formatFile("formtest.txt");
    //formatFile("mnemos_uebersetzt.txt");
    //mnem2bin("mnemos_uebersetzt.txt_fmtd.txt");

    //bin2mnem("mnemos_uebersetzt.txt_fmtd.txt_output.bin");
    return 0;
} */

/*
mnem2bin(char filename[]): erstellen einer neuen .bin Datei.
Im Parameter wird ein Dateipfad angegeben. Dieser wird ge�ffnet und gelesen.
Anhand des Inhaltes werden die Position in dem Array des Typen cmd, der Opcode sowie die Adresse ausgelesen
R�ckgabewerte:
    1: Datei wurde nicht gefunden
    0: Bin�rdatei wurde erfolgreich erstellt
*/

int mnem2bin(char* filename) {
    //printf("%s\n", filename);
    // Formattierung der Ursprungsdatei um besser auslesen zu k�nnen
    formatFile(filename);

    // �ffnen der .txt Datei mit dem Assemblercode
    FILE *asmfile;
    asmfile = fopen(filename, "r");

    // Variablen die sp�ter zur konvertierung in Hex genutzt werden
    unsigned long int uc_opcode, uc_address;

    // Endpointer der f�r konvertierung in Hex n�tig ist
    char *endptr = NULL;

    // a ist der Z�hler f�r die Anzahl an Commands in der Textdatei (z�hl die Zeilen)
    int a = 0;

    // Error 1: Datei konnte nicht gefunden werden
    if (asmfile == NULL) {
        return 1;
    }

    char line[256];
    cmd commands[1024];

    // Vorbef�llen des Arrays mit dem Pakettypen (0x02) und den Werten 0 (0x00), da immer aufgef�llt werden soll
    for(int i=0; i < sizeof(commands) / sizeof(commands[0]); i++){
        commands[i].pakettyp = strtoul("0x02", &endptr, 16);
        commands[i].opCode = strtoul("0x00", &endptr, 16);
        commands[i].adr = strtoul("0x00", &endptr, 16);
    }

    // Lesen jeder Zeile
    while (fgets(line, sizeof(line), asmfile) != NULL) {
        char *tok = strtok(line, ":"); // Zeichen vor dem ':' wird tokenized damit die die Position in der BIn�rdatei festgestellt werden kann
        //printf("Substring: %s\n", tok);
        int pos = strtoul(tok, &endptr, 16);
        //printf("int-Token: %d\n", test);
        if (tok != NULL) {
            tok = strtok(NULL, "\t\n"); // Jedes Zeichen vor einem Zeilenumbruch wird tokenized um daraus Mnemonic Befehl und Adresse zu lesen
            if (tok != NULL) {
                // Suche nach Mnemonic in dem Mapping
                for (int i = 0; i < sizeof(mnemonicMappings) / sizeof(mnemonicMappings[0]); i++) {
                    // Wenn Mnemonic in Mapping gefunden werden konnte, wird der Bin�re Partnerwert im Array an der Position pos im opCode gespeichert. Die letzten 2 Zeichen werden als adr gespeichert
                    if(strstr(tok, mnemonicMappings[i][0]) != NULL){
                        int len = strlen(tok);
                        const char *adrString = &tok[len-3];
                        char adrHex[10];
                        snprintf(adrHex, sizeof(adrHex), "0x%s", adrString);
                        // Umwandlung der Hex-Strings in Hex-hex
                        uc_address = strtoul(adrHex, &endptr, 16);
                        uc_opcode = strtoul(mnemonicMappings[i][1], &endptr, 16);
                        //printf("%s, %s\n", mnemonicMappings[i][1], adrHex);
                        //printf("%x, %x\n", uc_opcode, uc_address);
                        commands[pos].opCode = uc_opcode;
                        commands[pos].adr = uc_address;
                        a++;
                        break;
                    }
                }
            }
        }
    }

    // Bin�rdatei wird erstellt und mit den Werten im Array bef�llt
    char outputFilename[256];
    strncpy(outputFilename, filename, sizeof(outputFilename));
    strcat(outputFilename, "_output.bin");

    FILE *binFile = fopen(outputFilename, "wb");
    fwrite(commands, sizeof(cmd), 1024, binFile);

    /*
    for(int i = 0; i < a; i++){
        printf("%x, %x\n", commands[i].opCode, commands[i].adr);
    } */
    

    // Schlie�en der ge�ffneten Dateien
    fclose(asmfile);
    fclose(binFile);

    return 0;
}


void formatFile(char* filename) {
    //printf("%s\n", filename);
    // inputFile ist die Datei die zu formattieren ist. Diese wird formattiert in die Datei outputFile gespeichert
    FILE *inputFile = fopen(filename, "r");

    // outputFile bekommt die _fmtd.txt-Endung um zu zeigen dass dies die formatierte Datei ist
    char outputFilename[256];
    strncpy(outputFilename, filename, sizeof(outputFilename));
    strcat(outputFilename, "_fmtd.txt");

    if (inputFile == NULL) {
        perror("Datei konnte nicht geoeffnet werden!\n");
        return;
    }

    FILE *outputFile = fopen(outputFilename, "w");

    char line[256];
    while (fgets(line, sizeof(line), inputFile) != NULL) {
        // Kommentare die durch '#', ';' begonnen werden/beinhalten, werden bis zum letzten Zeichen der Zeile ignoriert
        char *hashPos = strchr(line, '#');
        char *semicolonPos = strchr(line, ';');
        if (hashPos != NULL) *hashPos = '\0';
        if (semicolonPos != NULL) *semicolonPos = '\0';

        // Leerzeichen, Tabulator und Zeilenumbr�che werden ignoriert
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
