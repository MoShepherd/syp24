#ifndef BREAKPOINTMANAGER_H
#define BREAKPOINTMANAGER_H

#include <stdio.h>
#include <stdlib.h>
#include <ncurses.h>

// verkettete Liste f�r Adressen (Breakpoints)
typedef struct Breakpoint {
    unsigned long long hexAddress;
    struct Breakpoint* next;
} Breakpoint;

int addBreakpoint(Breakpoint** breakpoint, unsigned long long address);
int removeBreakpoint(Breakpoint** breakpoint, unsigned long long address);
Breakpoint* getBreakpoint(Breakpoint** top, int index);
void printBreakpoints(Breakpoint* breakpoint, int y, int x);
void delList(Breakpoint** top);

#endif // BREAKPOINTMANAGER_H
