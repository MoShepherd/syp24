# Makefile

# Compiler and flags
CC = gcc
CFLAGS = -Wall -Wextra

# Source files
SRC_DIR = ./main/src
SRC_FILES = main.c auswahlmenu.c configserial.c filechooser.c bootloader.c statusbar.c config.c ../../compiler/Compiler.c ../../uart/src/uart.c debugger.c breakpointmanager.c ../../texteditor/Datei.c ../../texteditor/editLine.c ../../texteditor/prompt.c
SRCS = $(addprefix $(SRC_DIR)/,$(SRC_FILES))

INCLUDE_DIRS = -I./main/includes -I./texteditor -I./compiler

# Include directory

# Output directory
OUT_DIR = ./main/bin

# Output executable
TARGET = bootloader

# Libraries
LIBS = -lncurses

# Compile and link
$(OUT_DIR)/$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) $(INCLUDE_DIRS) $(SRCS) $(LIBS) -o $@

# Phony target to clean the build
.PHONY: clean
clean:
	rm -f $(OUT_DIR)/$(TARGET)

# Phony target to run the executable
.PHONY: run

run: 
	cd main/bin && ./$(TARGET)
