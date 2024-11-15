#include <stdio.h>
#include <stdlib.h>

/**
 * \brief cpnfig(): öffnet das Fenster für Dateibrowser des Betriebsystems um eine Datai auszuwählen;
 *  es speichert den Pfad der ausgewählten datei als Char* und zeigt diese an.
 *
 * 
 * 
 * @todo Execute wurde noch nicht implementiert.
*/


extern int baud;
extern char* comport_path;
// Structure to hold configuration variables

// Function to save configuration to a file
void saveConfigToFile(char *filename) {
    FILE *file = fopen(filename, "w");
    if (file != NULL) {
        fprintf(file, "Baudrate=%d\nComport=%s", baud, &comport_path);
        fclose(file);
        printf("Configuration saved to file successfully.\n");
    } else {
        printf("Error opening file for writing.\n");
    }
}

// Function to read configuration from a file
void readConfigFromFile(char *filename) {
    FILE *file = fopen(filename, "r");
    if (file != NULL) {
        char line[100]; // Assuming lines in the file are not longer than 100 characters
        while (fgets(line, sizeof(line), file) != NULL) {
            int baudrate;
            if (sscanf(line, "Baudrate=%d", &baudrate) == 1) {
            baud = baudrate;
            // if (sscanf(line, "Baudrate=%d", &baud) == 1) {
                // Baudrate line found
            } else if (sscanf(line, "Comport=%s", &comport_path) == 1) {
                // Comport line found
            }
        }
        fclose(file);
    } else {
        printf("Could not open config file!\n");
    }
}
