#include <stdbool.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <sys/select.h>
#include <ncurses.h>

#include "../include/uart.h"
#include "../../main/includes/statusbar.h"

#define SERIAL_PORT "/dev/ttyUSB1"

void initNcurses() {
    initscr();
    cbreak();
    noecho();
    keypad(stdscr, TRUE);
}


int main() {
    initNcurses();
    printw("test main program for uart mem tx");
    refresh();
    // open uart port  
    int fd_uart = open(SERIAL_PORT, O_RDWR | O_NOCTTY | O_SYNC);

    if (fd_uart < 0) {
        perror("Error opening serial port");
        exit(EXIT_FAILURE);
    }
    // configure uart
    set_interface_attribs(fd_uart, B115200, 0);

    // bootloader packet buffer
    uint8_t packet_header;
    uint16_t packet_data;
    char packet_buf[3];

    // read .bin file to transmit
    char *mem_image;
    off_t mem_size;
    int file_status = open_file("/home/jonas/tin/SYP/team04/host_app/uart/2big.bin", &mem_image, &mem_size);
    // int file_status = open_file("/home/jonas/tin/SYP/team04/host_app/tests/002_uart_tx/test.bin", &mem_image, &mem_size);
    if (file_status < 0){
        // close(fd_file);
        close(fd_uart);
        exit(EXIT_FAILURE);
    }

    // send binary transmit command and await answer packet
    // uart_tx_bl_packet(fd_uart, BL_TYPE_BIN_DATA, CMD_HOST_UPLOAD_RAM);
    uart_tx_bl_packet(fd_uart, BL_TYPE_CMD_HOST_PC, CMD_HOST_UPLOAD_RAM);
    uart_rx_bl_packet(fd_uart, packet_buf);

    // check if response is upload-in-progress-state of the decoder
    if(packet_buf[0] == BL_TYPE_ACK && packet_buf[2] == STAT_UPL_IN_PROG){
        printStatusLine("start transmission: ");
        // printf("start transmission: \n");
    }

    uint8_t err = tx_mem_image(fd_uart, mem_image, mem_size);

    // if (err == ERR_TRANS_OVERFLOW){
    //     printf("transmission overflow!");
    // }
    // if (err == ERR_TRANS_INCOMPLETE){
    //     printf("transmission incomplete!");
    // }

    // get status after transmitting the image;
    tcflush(fd_uart, TCIFLUSH);
    uart_tx_bl_packet(fd_uart, BL_TYPE_CMD_HOST_PC, CMD_HOST_STATUS_QUERY);
    uart_rx_bl_packet(fd_uart, packet_buf);
    uart_tx_bl_packet(fd_uart, BL_TYPE_CMD_HOST_PC, CMD_HOST_STATUS_QUERY);
    uart_rx_bl_packet(fd_uart, packet_buf);
    // error Auswertung
    if(packet_buf[0] == BL_TYPE_ERR){
        packet_data |= packet_buf[1] << 8;
        packet_data |= packet_buf[2];
        if(packet_data == ERR_BUSY)
            printf("[ err ] Memory transmission in progress: Another operation is currently being executed.");
        if(packet_data == ERR_TRANS_INCOMPLETE)
            printf("[ err ] Memory image transmission incomplete: The transmission was interrupted or not fully completed.");
        if(packet_data == ERR_TRANS_OVERFLOW)
            printf("[ err ] Memory image overflow: The transmitted image is too large for the available RAM.");
        if(packet_data == ERR_TRANS_NOT_STARTED)
            printf("[ err ] Memory transmission has not started yet!");
    } else if (packet_buf[0] == STAT_TRANS_COMPLETE){
        printf("[  !  ] Image successfully transmitted!");
    }

    // Clean up
    free(mem_image);
    // close(fd_file);
    close(fd_uart);
    exit(1);
    return 0;
}
