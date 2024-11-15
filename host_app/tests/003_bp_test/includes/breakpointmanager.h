#ifndef BREAKPOINTMANAGER_H
#define BREAKPOINTMANAGER_H

#include <stdio.h>
#include <stdlib.h>

// verkettete Liste f�r Adressen (Breakpoints)
typedef struct Breakpoint {
    unsigned long long hexAddress;
    struct Breakpoint* next;
} Breakpoint;


int addBreakpoint(Breakpoint** breakpoint, unsigned long long address);
int removeBreakpoint(Breakpoint** breakpoint, unsigned long long address);
void printBreakpoints(Breakpoint* breakpoint, int y, int x);
void delList(Breakpoint** top);
void printf_breakpoints(Breakpoint* top);
void getBreakpoints(Breakpoint** top, char *ret, size_t retSize);

#endif // BREAKPOINTMANAGER_H
