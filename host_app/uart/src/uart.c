#include <stdbool.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <sys/select.h>

#include "../include/uart.h"
#include "../../main/includes/statusbar.h"

int timeout_enabled = 0;

/**
 * \brief Konfiguriert die UART Schnittstelle mit teils gesetzten, teils parametrisierten Konfigurationen. 
 *
 * @param fd UART Handle
 * @param speed Baudrate der UART Verbindung
 * @param parity Anzahl an Parity Bits
*/
void set_interface_attribs(int fd, int speed, int parity) {
    struct termios tty;
    memset(&tty, 0, sizeof(tty));
    if (tcgetattr(fd, &tty) != 0) {
        perror("error from tcgetattr");
        exit(EXIT_FAILURE);
    }

    cfsetospeed(&tty, speed);
    cfsetispeed(&tty, speed);

     tty.c_cflag &= ~PARENB; // Clear parity bit, disabling parity (most common)
    tty.c_cflag &= ~CSTOPB; // Clear stop field, only one stop bit used in communication (most common)
    tty.c_cflag &= ~CSIZE; // Clear all bits that set the data size 
    tty.c_cflag |= CS8; // 8 bits per byte (most common)
    tty.c_cflag &= ~CRTSCTS; // Disable RTS/CTS hardware flow control (most common)
    tty.c_cflag |= CREAD | CLOCAL; // Turn on READ & ignore ctrl lines (CLOCAL = 1)

    tty.c_lflag &= ~ICANON;
    tty.c_lflag &= ~ECHO; // Disable echo
    tty.c_lflag &= ~ECHOE; // Disable erasure
    tty.c_lflag &= ~ECHONL; // Disable new-line echo
    tty.c_lflag &= ~ISIG; // Disable interpretation of INTR, QUIT and SUSP
    tty.c_iflag &= ~(IXON | IXOFF | IXANY); // Turn off s/w flow ctrl
    tty.c_iflag &= ~(IGNBRK|BRKINT|PARMRK|ISTRIP|INLCR|IGNCR|ICRNL); // Disable any special handling of received bytes

    tty.c_oflag &= ~OPOST; // Prevent special interpretation of output bytes (e.g. newline chars)
    tty.c_oflag &= ~ONLCR; // Prevent conversion of newline to carriage return/line feed
    // tty.c_oflag &= ~OXTABS; // Prevent conversion of tabs to spaces (NOT PRESENT ON LINUX)
    // tty.c_oflag &= ~ONOEOT; // Prevent removal of C-d chars (0x004) in output (NOT PRESENT ON LINUX)

    tty.c_cc[VTIME] = 10;    // Wait for up to 1s (10 deciseconds), returning as soon as any data is received.
    tty.c_cc[VMIN] = 3;      // minimum of 3 bytes must be in rcv buffer, to return for read()

    if (tcsetattr(fd, TCSANOW, &tty) != 0) {
        perror("error from tcsetattr");
        exit(EXIT_FAILURE);
    }
}
/**
 * \brief Überträgt ein Bootloader Paket (3 Byte) per UART Schnittstelle
 *
 * @param fd_uart UART Handle
 * @param pack_type Bootloader Pakettyp - MACROs in /host_app/uart/include/uart.h
 * @param pack_data Bootloader Paketdaten - MACROs in /host_app/uart/include/uart.h
*/
void uart_tx_bl_packet(int fd_uart, uint8_t pack_type, uint16_t pack_data){
    uint8_t buf[3];
    buf[0] = pack_type;
    buf[1] = (pack_data >> 8) & 0xFF;   // Extract the high byte
    buf[2] = pack_data & 0xFF;          // Extract the low byte
    write(fd_uart, buf, 3);
}

/**
 * \brief Empfängt ein Bootloader Paket (3 Byte) per UART Schnittstelle
 *
 * @param fd_uart UART Handle
 * @param data gesamtes Bootloader Paket
*/
int uart_rx_bl_packet(int fd_uart, uint8_t *data){
    int res;
    res = read(fd_uart, data, 3);
    if(res <= 0) {
        return -1; 
    }
    return 1;
}

/**
 * \brief Überträgt ein gesamtes Bootloader Binärimage (3072 Byte) per UART Schnittstelle
 *
 * @param fd_uart UART Handle
 * @param image gesamtes Bootloader Binärimage
 * @param size Größe des Binärimage in Byte
*/
uint8_t tx_mem_image(int fd_uart, uint8_t *image, int size){
    if (size % 3 != 0){
        printStatusLine("[ err ] File Size not a multiple of 3 Bytes!");
        return -1;
    }
    // write(fd_uart, image, size);
    uint8_t rcv_buffer[3];
    for (int i = 0; i < size/3; i++) {
        write(fd_uart, &image[i*3], 3);
        // uart_rx_bl_packet(fd_uart, rcv_buffer);
        double percent = (i/(double)size * 100) * 3;
        char buf[10]; 
        sprintf(buf, "%.2f% %\n", percent);
        printStatusLine(buf);
    fflush(stdout); 
    }
}

/**
 * \brief Liest ein gesamtes Binärimage in einen Buffer
 *
 * @param filepath Pfad der zu öffnenden Datei
 * @param mem_image Pufferspeicher, in welchen die Datei eingelesen wird
 * @param file_size Größe der zu lesenden Datei in Byte
*/
int open_file(char *filepath, char **mem_image, off_t *file_size){
    int fd_file = open(filepath, O_RDONLY);

    if (fd_file < 0) {
        perror("Error opening file");
        return -1;
    }
    // Determine the size of the file
    *file_size = lseek(fd_file, 0, SEEK_END);
    lseek(fd_file, 0, SEEK_SET);

    // Read the file content into a buffer
    *mem_image = malloc(*file_size);
    if (*mem_image == NULL) {
        perror("Error allocating memory");
        return -1;
    }

    ssize_t bytes_read = read(fd_file, *mem_image, *file_size);
    if (bytes_read != *file_size) {
        return -1;
    }
}
