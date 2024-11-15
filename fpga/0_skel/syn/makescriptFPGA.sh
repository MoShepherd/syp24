#!/bin/sh
# Der Name des toplevel_entity wir hier angeben (selbst editieren)
toplevel_entity=svnr
svnrfile=../mnemos/if1.asm
#svnrfile=bigaddress.asm
MODULE=ghdl


toplevel_entity=svnr
echo "Erzeuge Waveform für Toplevel Entity \"$toplevel_entity\""

# Maximale Simulationszeit (editierbar)
stime=20000ns

# Ab hier kommen keine vom Benutzer editierbaren Einstellungen 
# Anlegen des Arbeistverzeichnisses (falls noch nicht da)
mkdir -p work

# Löschen der alten Simulations-Artefakte
rm -f work/*

#
# Wandlen des Programms von SVNR Text in VHDL Simulation
#
../bin/svnr2vhd $svnrfile ../rtl/mem_init_package.vhd
if [ $? -ne 0 ]; then exit 1; else echo "--> OK" ; fi # Bei Rückgabe 0 wars ok

# Importieren ALLER .vhd Dateien
# in die Bibliothek mit dem Namen work
# Die Bibliothek wird im Directory work/ angelegt z.B. work-obj93.cf
ghdl -i  --work=work --workdir=work ../rtl/*.vhd
if [ $? -ne 0 ]; then exit 1; else echo "--> OK" ; fi # Bei Rückgabe 0 wars ok

# Analyse und Elaboration der VHDL Dateien in der Bibliothek work
# Letzter Parameter ist der Name der top-level Entity
# Es wird die auführbare Datei mit dem Namen der top-level Entity erzeugt
ghdl -m  --work=work -Pwork  --workdir=work $toplevel_entity
if [ $? -ne 0 ]; then exit 1; else echo "--> OK" ; fi # Bei Rückgabe 0 wars ok


# pcf-File zur Synthese in das work Verzeichnis kopieren

cp $toplevel_entity.pcf work/

# in das Verzeichnis work wechsel, wo sich das compilierte Programm befindet

cd work

# mit yosys wird der bereits compilierte VHDL-Code synthetisiert

yosys -m $MODULE -p 'ghdl '$toplevel_entity'; synth_ice40 -json '$toplevel_entity'.json' 2> yosys_err.log | tee yosys.log
if [ $? -ne 0 ]; then
    echo "see *log"
    cat yosys_err.log
    exit 1;
else
    echo "--> OK" ;
fi 


# synthetisiertes Programm für den ice40-Stick aufbereitet
# aus der .pcf Datei werden die Pins des FPGAs platziert und geroutet

nextpnr-ice40 --hx8k --package tq144:4k --freq 50 --pcf $toplevel_entity.pcf --asc $toplevel_entity.asc --json $toplevel_entity.json 2>&1 | tee nextpnr.log
if [ $? -ne 0 ]; then
    echo "see *log"
    cat nextpnr_err.log
    exit 1;
else
    echo "--> OK" ;
fi 

# Binär File erzeugen:
#exit
icepack $toplevel_entity.asc $toplevel_entity.bin

# mit Binär-File den FPGA programmieren

iceprog $toplevel_entity.bin
