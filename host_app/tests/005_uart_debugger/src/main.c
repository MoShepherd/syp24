#include <fcntl.h>
#include <termios.h>
#include <sys/select.h>
#include <unistd.h>

#include <ncurses.h>

#include <string.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include "../includes/uart.h"
#include "../includes/statusbar.h"

#define SERIAL_PORT "/dev/ttyUSB1"


int fd_uart = 0;

void initNcurses() {
    initscr();
    cbreak();
    noecho();
    keypad(stdscr, TRUE);
}

int init_uart(){
    fd_uart = open(SERIAL_PORT, O_RDWR | O_NOCTTY | O_SYNC);
    if (fd_uart < 0) {
        perror("Error opening serial port");
        exit(EXIT_FAILURE);
    }
    // configure uart
    set_interface_attribs(fd_uart, B115200, 0);
}


void t0(){
/*
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
*/
}

int t1(){ //erstes Test zum senden und empfangen von uart
    uint8_t packet_header;
    uint16_t packet_data;
    char packet_buf[3];
	char content[100];
		
	init_uart();
	
    uart_tx_bl_packet(fd_uart, BL_TYPE_CMD_HOST_PC, CMD_HOST_UPLOAD_RAM); // uart handle,packettyp,packetinhalt
    uart_rx_bl_packet(fd_uart, packet_buf);
	
	sprintf(content,"%02x%02x%02x", packet_buf[0], packet_buf[1], packet_buf[2]);
	printf("%s\n", content);	

	//closing handle
    close(fd_uart);
    return 0;
}

int t2_debugger_add_breakpoint(){ //Debugger 
    uint8_t packet_header;
    uint16_t packet_data;

    char packet_buf[3];
	char content[100];

	init_uart();


	// -----------------------
	//check status 010005
    uart_tx_bl_packet(fd_uart, BL_TYPE_CMD_HOST_PC, CMD_HOST_UPLOAD_RAM); // uart handle,packettyp,packetinhalt
	//expect STAT_INIT 0x01 
    uart_rx_bl_packet(fd_uart, packet_buf);
	sprintf(content,"%02x%02x%02x", packet_buf[0], packet_buf[1], packet_buf[2]);
	printf("%s\n", content);	

	// -----------------------

	//#define CMD_HOST_DEBUG_MODE     0x06     // Enter debug Mode, which allows for setting breakpoints etc.
    uart_tx_bl_packet(fd_uart, BL_TYPE_CMD_HOST_PC, CMD_HOST_DEBUG_MODE); // uart handle,packettyp,packetinhalt

	// expected #define STAT_DEBUG_INIT         0x05
    uart_rx_bl_packet(fd_uart, packet_buf);
	sprintf(content,"%02x%02x%02x", packet_buf[0], packet_buf[1], packet_buf[2]);
	printf("%s\n", content);	

	// ----------------------------
// #define DEBUG_SET_BP            0x0102  // to set breakpoint, send "set breakpoint" command with 0x040002, followed by the 16bit breakpoint address, prefixed with a debug packet header e.g. 0x04 1234 (first byte header, following 16 bit address)
    uart_tx_bl_packet(fd_uart, BL_TYPE_CMD_HOST_PC, DEBUG_SET_BP); // uart handle,packettyp,packetinhalt

	// expected#define STAT_ADD_BP             0x08
    uart_rx_bl_packet(fd_uart, packet_buf);
	sprintf(content,"%02x%02x%02x", packet_buf[0], packet_buf[1], packet_buf[2]);
	printf("%s\n", content);	

	// ----------------------------

	// #define BL_TYPE_ADDRESS         0x05
	// address 0x1010
    uart_tx_bl_packet(fd_uart, BL_TYPE_ADDRESS, 0x1010); // uart handle,packettyp,packetinhalt

	// unbekannt
    uart_rx_bl_packet(fd_uart, packet_buf);
	sprintf(content,"%02x%02x%02x", packet_buf[0], packet_buf[1], packet_buf[2]);
	printf("%s\n", content);	



	return 0;
}

int main() {
	t1();
	return 0;
}
