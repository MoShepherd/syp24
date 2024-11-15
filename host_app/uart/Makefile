CURRENT_DIR := $(CURDIR)

CC = gcc
CFLAGS = -Wall
SRCS = src/uart.c src/main.c $(CURRENT_DIR)/../main/src/statusbar.c
TARGET = bin/uart_tx

# Libraries
LIBS = -lncurses

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) $(LIBS) -o $@ $^

install: $(TARGET)
	# No installation needed as it's already in the desired directory

clean:
	rm -f $(TARGET)
