# Makefile

# Compiler and flags
CC = gcc
CFLAGS = -Wall -Wextra

# Source files
SRC_DIR = ./src
SRC_FILES = main.c breakpointmanager.c

SRCS = $(addprefix $(SRC_DIR)/,$(SRC_FILES))

# Include directory
INCLUDE_DIR = ../main/includes

# Output directory
OUT_DIR = ./bin

# Output executable
TARGET = bootloader

# Libraries
LIBS = -lncurses

# Compile and link
$(OUT_DIR)/$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -I$(INCLUDE_DIR) $(SRCS) $(LIBS) -o $@

# Phony target to clean the build
.PHONY: clean
clean:
	rm -f $(OUT_DIR)/$(TARGET)

# Phony target to run the executable
.PHONY: run
run: $(OUT_DIR)/$(TARGET)
	$(OUT_DIR)/$(TARGET)
