#!/bin/sh
# Der Name des toplevel_entity wir hier angeben (selbst editieren)
#toplevel_entity=cntHierarch_tb
svnrfile=snake.asm
#svnrfile=bigaddress.asm
#svnrfile=multiplikation.asm

toplevel_entity=svnr_tb
echo "Erzeuge Waveform für Toplevel Entity \"$toplevel_entity\""

# Maximale Simulationszeit (editierbar)
stime=100us

# Ab hier kommen keine vom Benutzer editierbaren Einstellungen 
# Anlegen des Arbeistverzeichnisses (falls noch nicht da)
mkdir -p work

# Löschen der alten Simulations-Artefakte
rm -f work/*

#
# Wandlen des Programms von SVNR Text in VHDL Simulation
#
./svnr2vhd $svnrfile src/mem_init_package.vhd
if [ $? -ne 0 ]; then exit 1; else echo "--> OK" ; fi # Bei Rückgabe 0 wars ok

# Importieren ALLER .vhd Dateien
# in die Bibliothek mit dem Namen work
# Die Bibliothek wird im Directory work/ angelegt z.B. work-obj93.cf
ghdl -i  --work=work --workdir=work src/*.vhd
if [ $? -ne 0 ]; then exit 1; else echo "--> OK" ; fi # Bei Rückgabe 0 wars ok

# Analyse und Elaboration der VHDL Dateien in der Bibliothek work
# Letzter Parameter ist der Name der top-level Entity
# Es wird die auführbare Datei mit dem Namen der top-level Entity erzeugt
ghdl -m  --work=work -Pwork  --workdir=work $toplevel_entity
if [ $? -ne 0 ]; then exit 1; else echo "--> OK" ; fi # Bei Rückgabe 0 wars ok

# Aufruf der erzeugten Datei mit Simulationsparametern
# Es wird maximal bis zur --stop-time simuliert
# Es wird die waveform Datei "waveform.ghw" erzeugt
ghdl -r --work=work -Pwork --workdir=work $toplevel_entity --wave=waveform.ghw --stop-time="$stime" --stop-delta=100000
if [ $? -ne 0 ]; then exit 1; else echo "--> OK" ; fi # Bei Rückgabe 0 wars ok

# Aufruf des Simulators als Child-Prozess (& dahinter), damit 
# sich dieses Script beenden kann
# --dump = Name der waveform Datei (hier waveform.ghw), 
#          die von der erzeugten Datei generiert wurde
# --save = Savefile von gtkwave, Einstellungen der Waveforms können 
#           gespeichert werden im Menü File -> "Write Save File"
gtkwave --dump=waveform.ghw --save ./gtkwave_config.gtkw &
