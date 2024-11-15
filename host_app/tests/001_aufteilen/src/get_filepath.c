//extern selected_file;
extern current_file; // modusFilechooser = 0
extern current_binary; // modusFilechooser = 1
int modusFilechooser; // welche File ausgewählt wird

// Output filepath
char* get_filepath() {
    if(modusFilechooser == 0){
        return current_file;
    } else if(modusFilechooser == 1){
        return current_binary;
    }
}
