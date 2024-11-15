#include "../includes/breakpointmanager.h"
#include <stdint.h>

int t1(){
    Breakpoint *bp = NULL;
    unsigned int breakpoint; // für Konvertierung
	breakpoint = 0x1010;
    addBreakpoint(&bp, breakpoint);
	printf_breakpoints(bp);
	return 0;
}


int main(int argc,char** argv){
	t1();
	return 0;
}
