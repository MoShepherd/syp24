#include <stdint.h>
#include <stddef.h>

// defines for uart config
// #define SERIAL_PORT "/dev/ttyUSB2" // Change this to your serial port
#define TIMEOUT_VAL 200 // timeout in ms

// Bootloader packet types
#define BL_TYPE_ACK             0x00   // Acknowledgement for message
#define BL_TYPE_CMD_HOST_PC     0x01   // Host PC Command
#define BL_TYPE_BIN_DATA        0x02   // Binary transmit packet
#define BL_TYPE_ERR             0x03   // Error packet
#define BL_TYPE_DEBUG           0x04
#define BL_TYPE_ADDRESS         0x05

// Host PC Commands with CMD_HOST_ prefix
#define CMD_HOST_EXECUTE        0x01     // Execute, siehe LF07
#define CMD_HOST_UPLOAD_RAM     0x02     // Upload to RAM, siehe LF04
#define CMD_HOST_LOAD_FLASH     0x03     // Load to FLASH, siehe LF05
#define CMD_HOST_LOAD_FROM      0x04     // Load from FLASH, siehe LF06
#define CMD_HOST_STATUS_QUERY   0x05     // Statusabfrage - Der Host PC fragt den derzeitigen Status des FPGA ab
#define CMD_HOST_DEBUG_MODE     0x06     // Enter debug Mode, which allows for setting breakpoints etc.
#define CMD_HOST_RESET          0x07     // Enter debug Mode, which allows for setting breakpoints etc.
#define CMD_HOST_STOP           0x08     // Enter debug Mode, which allows for setting breakpoints etc.

// Debug Packet Data (Bit 8-15 bestimmen Befehlssatz, in dem Fall DEBUG CMD)
// to send DEBUG commands, first enter DEBUG MODE with  0x010006 command.
#define DEBUG_SET_BP            0x0102  // to set breakpoint, send "set breakpoint" command with 0x040002, followed by the 16bit breakpoint address, prefixed with a debug packet header e.g. 0x04 1234 (first byte header, following 16 bit address)
#define DEBUG_DEL_BP            0x0103  // same with deleting breakpoints: 
#define DEBUG_WRITE_RAM         0x0106  // to write to specific ram address, send "write to ram" command 0x040006, followed by one packet containing the address (e.g. 0x04 1234), followed by a packet of ram data on this address (0x04 1111)
#define DEBUG_READ_RAM          0x0107

// Error  Codes
#define ERR_BUSY                0x10
#define ERR_TRANS_INCOMPLETE    0x11   
#define ERR_TRANS_OVERFLOW      0x12
#define ERR_TRANS_NOT_STARTED   0x13
#define ERR_NOT_VALID_PACKET    0x14

// Status Codes (states of Decoder state-machine)
#define STAT_INIT               0x01
#define STAT_UPL_IN_PROG        0x02
#define STAT_UPL_COMPLETE       0x03

#define STAT_RUNNING            0x06
#define STAT_RESETING           0x07
#define STAT_ADD_BP             0x08
#define STAT_DEL_BP             0x09
#define STAT_DEBUG_INIT         0x05


// Function prototypes
void uart_tx_bl_packet(int fd_uart, uint8_t pack_type, uint16_t pack_data);
int uart_rx_wait_for_byte(int fd_uart, uint8_t *received_char);
int uart_rx_bl_packet(int fd_uart, uint8_t *data);
void set_interface_attribs(int fd, int speed, int parity);
void uart_tx_data(int fd, const char *data, size_t size);
void uart_tx_byte(int fd, const char *data, int index);
uint8_t tx_mem_image(int fd_uart, __uint8_t *image, int size);
int open_file(char *filepath, char **mem_image, off_t *file_size);
int get_fpga_status(int fd_uart);
