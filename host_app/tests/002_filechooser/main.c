#include <ncurses.h>
#include <stdlib.h>
#include <string.h>

#define MAX_BUFFER_SIZE 1024
#define COLOR_MATRIX_GREEN 8

char* selected_file = NULL;

char* current_file = NULL; // modusFilechooser = 0
char* current_binary = NULL; // modusFilechooser = 1

//char current_file[500]; // modusFilechooser = 0
//char* current_binary[500]; // modusFilechooser = 1

int modusFilechooser = 0; // welche File ausgewählt wird
int mnem2bin(char* filename); 

void filechooser();
char* get_filepath();

void t1(){
	modusFilechooser = 0;
	filechooser();

    switch(modusFilechooser){
        case 0: // Current File
			printf("%s\n",current_file);
			mnem2bin(current_file);
			break;
		case 1:
			printf("%s\n",current_binary);
			mnem2bin(current_file);
			break;
		default: return;
	}
	printf("ich bin mit meinem leben in der mitte");
}

void t2(){
	mnem2bin("/home/ismail/2023-02-23 14-33-03.mkv");
}

void t3(){
	mnem2bin("\"/home/ismail/2023-02-23 14-33-03.mkv\"");
	printf("\"/home/ismail/2023-02-23\ 14-33-03.mkv\"");
}
int main() {
	t3();	
}
