################################
# write/read on adresses > 0xff
# execute on addresses > 0xff
0000:	JA20 			; Begin HP 20
0004:	0000			; reserviert lese Taster bS1..SW5 und SW
0005:	0000			; reseriert Schreibe auf 2 Hexdigit ANzeige an PMOD1
0006:	5555			; reserviert für LEDs D1..8
0007:	0000			; reserviert für Beep
0010:	0000			; const uint16_t k0 = 0
0011:	0003			; const uint16_t k3 = 3

0012:	000f			; uint16_t a =
0013:	0005			; uint16_t b = 
	################################
	# if (a == 3) { b++;} else {b--;}
	# if ( (a-3) == 0)
	# Beginn Hauptschleife
20:	LDM12			; Akku = a
21:	SUB11			; Akku = Akku + k0 ( dummy Rechnung f. ALU Flags)
22:	JZA2a			; spring zu if (true)
;;; 
23: 	LDM13			; Akku = b if (false)
24:	DEC00			; Akku--
25:	STM13			; b = Akku
26:	JA2f			; weiter, if (true) überspringen
;;;  27,28,29 leer
2a:	LDM13			; Akku = b if (true)
2b:	INC00			; Akku ++;
2c:	STM13			; b = Akku
2d:	NoOp00
2e:	NoOp00
2f:	JA2f			;weiter /ende

