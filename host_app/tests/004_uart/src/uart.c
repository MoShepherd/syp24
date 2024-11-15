#include <stdbool.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <sys/select.h>

#include "../includes/uart.h"
#include "../includes/statusbar.h"

void printStatusLine(char *);
int timeout_enabled = 0;

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

void uart_tx_data(int fd, const char *data, size_t size) {
    ssize_t n = write(fd, data, size);

    if (n != size) {
        perror("Error writing to UART");
    }
}

void uart_tx_byte(int fd, const char *data, int index) {
    write(fd, &data[index], 1);
}

void uart_tx_bl_packet(int fd_uart, uint8_t pack_type, uint16_t pack_data){
    uint8_t buf[3];
    buf[0] = pack_type;
    buf[1] = (pack_data >> 8) & 0xFF;   // Extract the high byte
    buf[2] = pack_data & 0xFF;          // Extract the low byte
    write(fd_uart, buf, 3);
}

int uart_rx_wait_for_byte(int fd_uart, uint8_t *received_char) {
    if (!timeout_enabled) {
        // If timeout is disabled, wait indefinitely
        return read(fd_uart, received_char, 1);
    }

    struct timeval timeout;
    fd_set read_fds;

    timeout.tv_sec = TIMEOUT_VAL / 1000;
    timeout.tv_usec = (TIMEOUT_VAL % 1000) * 1000;

    FD_ZERO(&read_fds);
    FD_SET(fd_uart, &read_fds);

    int result = select(fd_uart + 1, &read_fds, NULL, NULL, &timeout);

    if (result == -1) {
        perror("select");
        // Handle error
        return -1;
    } else if (result == 0) {
        printStatusLine("[err] Timeout occured!");
        return 0;
    } else {
        read(fd_uart, received_char, 1);
        return 1;
    }
}

int uart_rx_bl_packet(int fd_uart, uint8_t *data){
    int res;
    res = read(fd_uart, data, 3);
    if(res <= 0) {
        return -1; 
    }
    return 1;
}

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
        // if (rcv_buffer[0] == BL_TYPE_ACK){
        //     double percent = (i/(double)size * 100) * 3;
        //     char buf[10]; 
        //     sprintf(buf, "%.2f% %\n", percent);
        //     printStatusLine(buf);
        //     // fflush(stdout); // Flush the output buffer to ensure it is displayed immediately
        // } else if(rcv_buffer[0] == BL_TYPE_ERR){
        //     printStatusLine("an error occured!");
        //     return rcv_buffer[2];
        // }
    }
    // printf("\r100.00%%\n");
    fflush(stdout); 
}

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

int get_fpga_status(int fd_uart){
    uart_tx_bl_packet(fd_uart, BL_TYPE_CMD_HOST_PC, CMD_HOST_STATUS_QUERY);
}
