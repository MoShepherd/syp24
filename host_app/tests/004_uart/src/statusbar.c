#include <ncurses.h>
#include <string.h>

void printStatusLine(char *message) {
    int row, col;
    // Get the number of rows and columns in the terminal window
    int y, x;            // to store where you are
    getyx(stdscr, y, x); // save current pos
    getmaxyx(stdscr, row, col);

    int messageLength = strlen(message);
    int startX = 0; // start message at middle of last row 

    // Move the cursor to the last line and clear it
    move(row - 1, 0);
    clrtoeol();
    // Print the message at the center of the last line
    mvprintw(row - 1, startX, message);
    move(y, x);          // move back to where you were
    // Refresh the screen
    refresh();
}
