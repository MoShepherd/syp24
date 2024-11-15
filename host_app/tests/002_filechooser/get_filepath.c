//extern selected_file;
extern char* current_file; // modusFilechooser = 0
extern char* current_binary; // modusFilechooser = 1
extern int modusFilechooser; // welche File ausgewählt wird



// Output filepath
char* get_filepath() {
    if(modusFilechooser == 0){
        return current_file;
    } else if(modusFilechooser == 1){
        return current_binary;
    }
}
