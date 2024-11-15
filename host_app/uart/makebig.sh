#!/bin/bash

file_path="output.bin"

# Use dd to copy the second half and append it to the end of the file
dd if="$file_path" of="$file_path" bs=1 seek=$(($(wc -c < "$file_path") / 2)) skip=$(($(wc -c < "$file_path") / 2)) conv=notrunc

echo "File size after appending: $(wc -c < "$file_path") bytes"

