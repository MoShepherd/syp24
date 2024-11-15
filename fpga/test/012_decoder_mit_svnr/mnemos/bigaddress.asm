################################
# write/read on adresses > 0xff
# execute on addresses > 0xff
0000:	JA20 			; Begin HP 20
0004:	0000			; reserviert lese Taster bS1..SW5 und SW
0005:	0000			; reseriert Schreibe auf 2 Hexdigit ANzeige an PMOD1
0006:	0000			; reserviert für LEDs D1..8
0007:	0000			; reserviert für Beep
000A:	0010			; Maske fuer SW5
0010:	03C0			; Adresse die beschrieben werden solll
0011:	0777			; Konstante Bitmuster an
0012:	0000			; Konstante Bitmuster aus
0013:	03C0			; Konstante Startadresse
0014:	0400			; Konstante Endadresse
#0015:	ffff			; Konstatne Delay initialisierung
0015:	0002			; Konstatne Delay initialisierung
0016:	0000			; Delay Variable
0017:	0000			; Konstatne wird um soviel manipuliert
0018:	03E8			; Konstanter Ort im Display
0019:	0404   			; Wert am Display
	################################
	# Beginn Hauptschleife
20:	LDM11			; Akku=0777 M Bitmuster LED an
21:	STI10			; Akku an Addresse schreiben, die in Adresse 10 steht
22:	JA60			; Warteschleife
23:	LDM12			; Aku = 0000
24:	STI10			; Akku an Adresse schreiben
25:	LDI10			; 
26:	INC00			; Display adress ++
27:	STI10			;
28:	SUB14			; Adresse - Endadresse
29:	STM05
2A:	JNA20			; nicht 0, dann 200 noch nicht erreicht
2B:	LDM13			; Startadresse laden
2C:	STM10			; In Arbeitsadresse schreiben
2D:	JA20			; und von vorne

	#################
60:	LDM15   # Zählerkonstante
61:	STM16   # Zählvariable initialisieren delcnt = maxcnt
62:	JA70    # inneres delay (falls nötig)
63:	NoOp01  # SPrungziel fuer
64:	LDM16	#
65:	DEC00   # delcnt--
66:	STM16   #
67:	JNA62	# weitere
68:	LDM15 	# hole delayzeit
69:	SUB17
6a:	STM15
6b:	JA23	   # zurück in Hauptschleife
#8:	1234
	
70:	LDM04			;hole Taster in Akku
71:	AND0A			;Maskiere SW5 (0x10) aus
72:	JZA63			;zurueck, wenn nicht gedrückt
73:	LDM19			; Akku = Muster zu schreiben
74:	STI18			; An die konstatne Display Adresse schreoiben
75:	JA63


	#################
	# Initialisierung des Displays mit Irgendwas
3dc:	0f00
3c0:	0fff
3c1:	0111
3c2:	0001
3c3:	0010
3c4:	0100
3fe:	0f0f
3ff:	0404
