;;; Snake
;;; ;
;;;
;;; Spezial Adressen 0..0x0f
0000:	JM42 			; Begin HP an 190 (42)
0004:	0000			; reserviert lese Taster SW1..SW5 und SW ;
				;  SW1 bit0, SW5: bit4, SW6: bit 6 SW7:bit7 
0005:	0000			; reseriert Schreibe auf 2 Hexdigit ANzeige an PMOD1
0006:	0000			; reserviert für LEDs D1..8
0007:	0000			; reserviert für Beep

;;; Arrays und Display am Adressende Teil
;;;        uint16_t snake[64];       // 0x340 .. 0x37f
;;;  const uint16_t random_array[64] // 0x380 .. 0x3bf (s.u.)
;;;        uint16_t disp[64];        // 0x3c0 .. 0x3ff


;;; global genutze Variablen
0010:	0000	; uint16_t head = 0; // index im snake array
0011:	0000	; uint16_t tail = 0 // index im snake array
0012:	0000	; uint16_t headpos = 0;
0013:	0000	; uint16_t tailpos = 0;
0014:	0000	; uint16_t count_moves = 0;
0015:	0000	; uint16_t grow = 0; // wenn 1 lass die schlange wachsen
0016:	0000	; uint16_t len = 1
0017:	0000	; uint16_t random_pointer = 0;
0018:	0001	; uint16_t richt = 1 ;   // 0 = Nord, 1=Ost , 2 =Sued, 3 = West
0019:	0000	; delay1, val, r 
001a:	0000	; delay2
001b:	0000	; uint16_t c (buttons)
001c:	0000	; pdisp (pointer auf disp - array)
001d:	0000	; psnake (pointer auf snake), prandom (pointer auf random)
001e:	0000	; lokale Hilfsvariable: hilf, i 
001f:	0000	; Hilfsprungziel
;;; Konstanten ab 0x20
0020:	0008	; const uint16_t snake_color = 0xf;
0021:	0010	; const uint16_t food_color = 0xf0;
0022:	0f00	; const uint16_t error_color = 0xf00;
0023:	7fff	; const init_delay1 (innnere Schleife)
#0023:	0001	; const init_delay1 (innnere Schleife)
0024:	000c	; const init_delay2 (äussere Schleife)
0025:	0040	; 64, Abbruchbedingung f. viele Schleifen
0026:	0340	; Basisadresse snake-array
0027:	0380	; Basisadresse random-array
0028:	03c0	; Basisadresse disp
0029:	0000	; const 0
002a:	ffc0	; ~0x40 Maske für Überlauf > 63
002b:	0007	; Maske f. headpos
002c:	0008	; 8 +/- in headpos

;;; Sprungziele > 0x0100 für JM, JZM, JNM
0030:	0100			; void check_collision()
0031:	0110			; while(1) {}
0032:	0108			; if ... food_color
0033:	019b			; return von check_collision()
0034:	0127			; new_head_and_tail() if false
0035:	0146			; if grow == 0, if false / else
0036:	019c			; return von new_head_and_tail()
0037:	0150			; void increase_random_pointer(void);
0038:	0166			; return von increase_random_pointer (!!! mehrfache returns)
0039:	0160			; void drop_food_random(void);
003a:	0184			; return von drop_food_random
003b:	0180			; time_to_drop_food(void);
003c:	019d			; return von time_to_drop_food(void);
003d:	0197			; return von filldisplay() main() while(1)
003e:	0188			; void display(void);
003f:	0198			; return von display();
0040:	0199			; return von wait_and_checkkeys()
0041:	019a			; return von new_headpos()
0042:	0190			; main()
0043:	01b0			; clear_snake()
0044:	01b4			; clear_snake do{
0045:	0195			; return von clear_snake()
0046:	0120			; void new_head_and_tail(void);
	
;;; /*************************************/
;;; void wait_and_checkkeys(void) {
;;;   sleep(1);
;;;   char c[5];
;;;   fflush(stdin);
60:	LDA00
61:	STM1b	    		; c = 0;
62:	LDM24   		; Zählerkonstante äussere (init_delay2)
63:	STM1a    		; Zählvariable initialisieren delay2 = init_delay 
;;; 
64:	LDM23  			; do { Zählerkonstante innere (init_delay1)
65:	STM19  			;     delay1 = init_delay
;;; 
66:	LDM04			;     do {
67:	ADD29			;        Akku + 0 : setzeFlags
68:	JZA6d			;        if (button != 0)
69:	STM1b 			;           c = button_GPIO
6a:	Noop00			; ---------------- LDAxx
6b:	Noop00			; ---------------- STM_FLAG, ruecksprung hier
6c:	Noop00			; ---------------- JM increase_random_pointer (sozusagen randomize)
6d:	LDM19			;     
6e:	DEC00  			;         delay1 --
6f:	STM19  			;

70:	JNA66			;     } while (delay1 != 0)
71:	LDM1a			; 
72:	DEC00			;     delay2 --
73:	STM1a			;
74:	JNA64			; } while (delay2 != 0)
;;; Hole Tasterwert
;;;   scanf("%s",c); // wait
;;; 
;;;   if (c[0] == 'a') { // links
;;;     richt --;
;;;   }
75:	LDA01
76:	STM1e			; hilf = 0x01
77:	LDM1b
78:	AND1e			; Akku = c & 0x01
79:	JZA7d			; if ( (c & 0x01) != 0) { , also bit 0 gesetzt, SW1 = links
7a:	LDM18
7b:	DEC00			;   richt --;
7c:	STM18			; }
;;;   if (c[0] == 'd') { // rechts
;;;     richt ++;
;;;   }
7d:	LDA10			; 
7e:	STM1e			; hilf = 0x10
7f:	LDM1b			;
80:	AND1e			; akku = c & 0x10
81:	JZA85			; if ( (c & 0x10) != 0) { , also bit 4 gesetzt SW5 = rechts
82:	LDM18
83:	INC00			;   richt ++
84:	STM18			; }
;;;   richt = richt & 3; // Überlauf wegmaskieren
85:	LDA03
86:	STM1e 			; hilf = 0x03
87:	LDM18
88:	AND1e
89:	STM18 			; richt = richt & 3 
8a:	JM40			; Rücksprung in main
;;; }
;;; 
;;; /*************************************/
;;; void filldisplay(void) {
;;;     for (int i = 0; i<64  ;i++) disp[i]=0; // Display leeren
90:	LDA00
91:	STM1e			; i = 0;
92:	LDM28
93:	STM1c			; pdisp = &disp[0];
94:	LDM1c		   	; do {
95:	LDA00
96:	STI1c		   	;   *pdisp = 0;
97:	LDM1C
98:	INC00			;   pdisp ++;
99:	STM1C
9a:	LDM1e
9b:	INC00			;   i++;
9c:	STM1e
9d:	SUB25			; akku -= 64
9e:	JNA94		   	; } while (i != 64)
;;;     for (int i = 0; i<64  ;i++) if (snake[i]) disp[snake[i]&0x3f]=snake_color;
9f:	LDA00
a0:	STM1e		   	; i = 0;
a1:	LDM26
a2:	STM1d		   	; psnake = &snake[0];
a3:	LDI1d			; do {  Akku = snake[i]
a4:	STM19			;   val = *psnake
a5:	ADD29			;   Akku + 0 : setzeFlags
a6:	JZAab			;   if (snake[i] != 0) {
a7:	ADD28			;     akku = akku + disp
a8:	STM1c			;     pdisp = disp + snake[i]
a9:	LDM20			;     
aa:	STI1c			;     *pdisp = snake_color;
ab:	LDM1d			;   }
ac:	INC00			;   psnake++;
ad:	STM1d
ae:	LDM1e
af:	INC00		   	;   i++;
b0:	STM1e
b1:	sub25		   	; akku -= 64
b2:	JNAa3		   	; } while ( i != 64)
b3:	JM3d			; // jumpziel s. 197
;;; }
;;; /*************************************/
;;; void new_headpos(void) {
;;;     headpos = snake[head]; // & 0x3f;  // Marker löschen
b8:	LDM10			; head
b9:	ADD26			; 
ba:	STM1d			; psnake = snake + head
bb:	LDI1d			;
bc:	STM12			; headpos = *psnake
;;;     tailpos = snake[tail]; // & 0x3f;  // Marker löschen
bd:	LDM11			; tail
be:	ADD26
bf:	STM1d			; psnake = snake + tail
c0:	LDI1d
c1:	STM13			; tailpos = *psnake
;;;     if (richt == 0) {      
;;;       headpos -= 8;
;;;       if (headpos > 63) headpos = headpos + 64; // Überlauf obere Grenze
;;;     }
c2:	LDM18
c3:	ADD29			; Akku + 0 : setzeFlags
c4:	JNAcf			; if (richt == 0) {
c5:	LDA08
c6:	STM1e			;   hilf = 8
c7:	LDM12
c8:	SUB1e
c9:	STM12			;   headpos -= 8;
ca:	AND2a			;   akku = akku & 0xffc0 (wird != 0 wenn > 63)
cb:	JZAcf			;   if ( (headpos & 0ffc0) != 0) {
cc:	LDM12			;
cd:	ADD25			;     headpos += 64;
ce:	STM12			;     
;;;     if (richt == 2) {      
;;;       headpos += 8;
;;;       if (headpos > 63) headpos = headpos + 64; // Überlauf untere Grenze
;;;     }
cf:	LDA02
d0:	STM1e			; hilf = 2
d1:	LDM18			;
d2:	SUB1e			; richt - 2
d3:	JNAde			; if ( (richt - 2 ) == 0) {
d4:	LDA08			;
d5:	STM1e			;   hilf = 8
d6:	LDM12
d7:	ADD1e
d8:	STM12			;   headpos += 8;
d9:	AND2a			;   akku = akku & 0xffc0 (wird != 0 wenn > 63)
da:	JZAde			;   if ( (headpos & 0ffc0) != 0) {
db:	LDM12			;
dc:	ADD25			;      headpos += 64;
dd:	STM12			;     
;;;     if (richt == 1) {      
;;;       headpos += 1;
;;;       if ((headpos & 0x7) == 0) headpos = headpos - 8; // Überlauf östliche Grenze
;;;     }
de:	LDA01
df:	STM1e			; hilf = 1
e0:	LDM18
e1:	SUB1e			; richt - 1
e2:	JNAeb			; if ( (richt -1) == 0) {
e3:	LDM12
e4:	INC00			;   headpos += 1;
e5:	STM12
e6:	AND2b			;   0x7 maskieren
e7:	JNAeb			;   if ( ( headpos & 0x7) == 0) {
e8:	LDM12			;
e9:	SUB2c			;       headpos = headpos - 8 ;
ea:	STM12			;
;;; 
;;;     if (richt == 3) {      
;;;       headpos -= 1;
;;;       if ((headpos & 0x7) == 7) headpos = headpos + 8; // Überlauf westliche Grenze
;;;     }
eb:	LDA03
ec:	STM1e
ed:	LDM18
ee:	SUB1e
ef:	JNAf9			; if ( ( richt - 3) == 0 ) {
f0:	LDM12
f1:	DEC00			;   headpos -= 1;
f2:	STM12
f3:	AND2b			;   0x7 maskieren
f4:	SUB2b			;    -7
f5:	JNAf9			;   if ( (headpos & 0x7) - 7 ) == 0) {
f6:	LDM12
f7:	ADD2c			; headpos = headpos + 8;
f8:	STM12			;
;;;     
;;;     headpos = headpos & 0x3f; // 6 Bit ausmaskiern bei Überlauf
f9:	LDA3f
fa:	STM1e		   ; hilf = 0x3f
fb:	LDM12		   ;
fc:	AND1e		   ; headpos = headpos & 0x3f
fd:	STM12		   ;
fe:	JM41		   ; zu 19A
;;; }
;;; /*************************************/
;;; vo*id check_collision() {
;;;    // Checke Kollision mit sich selbst
;;;     if (disp[headpos] == snake_color) { // Zielfeld ist Schlange
;;;       disp[headpos] = error_color;  // Kollision rot markieren
;;;       display();
;;;       while(1) {}              // Endlos pause bis reset
;;;     }
100:	LDM12			; heapos // jumpziel 0030
101:	ADD28			; +disp
102:	STM1c			; pdisp = disp + headpos
103:	LDI1c			; pdisp
104:	SUB20			; snake_color
105:	JNM31			; if ( (*pdisp - snake_color) == 0) {
106:	LDM22			;   error_color
107:	STI1c			;   *pdisp = error_color (pdisp ist noch aktuell)
108:	NoOp00			;   while(1) {} // jumpziel 0032
109:	NoOp00
10a:	NoOp00
10b:	NoOp00
10c:	NoOp00
10d:	NoOp00
10e:	NoOp00
10f:	JM32
;;;     if (disp[headpos] == food_color) { // Zielfeld ist Futter
;;;       grow = 1;
;;;     } 
110:	LDI1c			; jumpziel 0031
111:	SUB21
112:	JNM33		   	; if ( (*pdisp - food_color) == 0) {
113:	LDA01
114:	STM15		   	; grow = 1
115:	JM33			; 19b
;;;  }
;;; /*************************************/
;;; void new_head_and_tail(void){
;;;     head ++;                   // nächster Head-Pointer
120:	LDM10			;
121:	INC00			; head ++;
122:	STM10			;
;;;     if (head == 64) head = 0;  // Head Pointer Überlauf
123:	SUB25
124:	JNM34			; if ( (head - 64) == 0) {
125:	LDA00
126:	STM10			; head = 0;
;;;     snake[head] = headpos;     // neues snake Element speichern
127:	LDM10			;  // hier Jumpziel s. 0034
128:	ADD26			;
129:	STM1d			;  psnake = snake + head
12a:	LDM12
12b:	STI1d			; *psnake = headpos
;;;     disp[headpos]=snake_color; // neuen snake Kopf zeichnen
12c:	LDM12			;
12d:	ADD28
12e:	STM1c			; pdisp = disp + headpos
12f:	LDM20
130:	STI1c			; *pdisp = snake_color
;;; 
;;;     if (grow == 0) {
131:	LDM15
132:	ADD29			; Akku + 0 : setzeFlags
133:	JNM35			; if (grow == 0) {
;;;       snake[tail] = 0;           // letztes snake Element  löschen
134:	LDM11
135:	ADD26
136:	STM1d			; psnake = snake + tail
137:	LDA00
138:	STI1d			; *psnake = 0
;;;       disp[tailpos]=0x000;       // letzte snake Pixel löschen
139:	LDM13
13a:	ADD28
13b:	STM1c			; pdisp = disp + tailpos
13c:	LDA00
13d:	STI1c			; *pdisp = 0
;;;       tail ++;                   // nächster tail Pointer
13e:	LDM11
13f:	INC00			; tail++
140:	STM11
;;;       if (tail == 64) tail = 0;  // Tail Pointer Überlauf
141:	SUB25			; 
142:	JNM36			; if ( (tail - 64) == 0
143:	LDA00
144:	STM11			; tail = 0
145:	JNM36
;;;     } else {
;;;       grow = 0;
146:	LDA00			; // Jumpziel s. 0035
147:	STM15		   	; grow = 0
;;;       len++;
148:	LDM16
149:	INC00			; len ++
14a:	STM16
;;;     }
14b:	JNM36
;;; }
;;; /*************************************/
;;; void increase_random_pointer(void) {
;;;   random_pointer ++;
150:	LDM17
151:	INC00
152:	STM17
;;;   if ((random_pointer & 0x40) == 0x40)
153:	AND25
154:	JZM38		   	; 0166
;;;     random_pointer = 0;
155:	LDA00
156:	STM17
157:	JM38		   ;0166
;;; }
;;; /*************************************/
;;; void drop_food_random(void) {
;;;   uint16_t r;
;;;   do {                   
;;;     r=random_array[random_pointer]; // ZUfallszahl von 0..63
160:	LDM17			; // Jumpziel s. 0039
161:	ADD27
162:	STM1d			; prandom = random + random_pointer
163:	LDI1d
164:	STM19			; r = *prandom
;;;     increase_random_pointer();      // nächste Zufallszahl
165:	JM37		; 0150
;;;   } while(disp[r] != 0); // muss leer sein
166:	LDM19			; Jumpziel s. 0038
167:	ADD28
168:	STM1c			; pdisp = disp + r
169:	LDI1c
16a:	ADD29			; Akku + 0 : setzeFlags
16b:	JNM39			; } while ( (*pdisp) != 0) 
;;;   disp[r] = food_color;  Leeres Feld gefunden: Food platzieren
16c:	LDM19
16d:	ADD28
16e:	STM1c			; pdisp = disp + r
16f:	LDM21			; 
170:	STI1c			; *pdisp = food_color
171:	JM3a
;;; }
;;; /*************************************/
;;; void time_to_drop_food(void) {
;;;   if ((count_moves & 0x7) == 0)  // jeder 4./8....
180:	LDM14		   	; count_moves
181:	AND2b
182:	JNM3a
;;;     drop_food_random();
183:	JM39
;;;   count_moves++;
184:	LDM14
185:	INC00			; count_moves ++
186:	STM14
187:	JNM3c
;;; }
;;; /*************************************/
;;; void display(void) {
;;;   printf("Moves: %d Len: %d\n",count_moves,len)
;;;
;;; count_moves in 0014 auf LEDS schreiben (in bin)
0188:	LDM14
0189:	STM06
;;; Laenge in 0016 auf Hexseg schreiben (in hex)
018a:	LDM16
018b:	STM05
018c:	JM3f
;;;  }
;;; /*************************************/
;;; int main() {
;;;   richt = 1;
190:	LDA01
191:	STM18
;;;   clear_snake() // and init to snake[0] = 17;
192:	JM43
;;; 
;;;   filldisplay();
195:	JA90			; filldisplay
196:	Noop00			; 
;;;   while(1) {
;;;     display();
197:	JM3e 			;JM3e
;;;     wait_and_checkkeys();
198:	JA60
;;;     /*******************/
;;;     new_headpos();
199:	JAb8
;;;     check_collision();
19a:	JM30			;JM30
;;;     new_head_and_tail();
19b:	JM46			;
;;;     time_to_drop_food();
19c:	JM3b			;JM3b
;;;     
;;;   }
19d:	JM3d			; zu 0197: display()
;;;   return 0;
;;; }

;;; /***************************************/
;;; clear_snake
1b0: 	LDA00
1b1:	STM1e			; i = 0;
1b2:	LDM26
1b3:	STM1d			; psnake = snake;
1b4:	LDM1d		   	; do {
1b5:	LDA00
1b6:	STI1d		   	;   *psnake = 0;
1b7:	LDM1d
1b8:	INC00			;   psnake ++;
1b9:	STM1d
1ba:	LDM1e
1bb:	INC00			;   i++;
1bc:	STM1e
1bd:	SUB25			; akku -= 64
1be:	JNM44		   	; } while (i != 64)
;;; snake[0] = 17;
1bf:	LDM26
1c0:	STM1d			; psnake = snake
1c1:	LDA11			; 11 = dez. 17
1c2:	STI1d			; *psnake = 17
1c3:	JM45

# const uint16_t random_array[64] = { 7,49, 9,12,14,38,42, 5,  // 0x380.. 0x3bf
# 				    19, 2,43,10, 7,62,22,46,
# 				    28,50,21,18,39,30,33,23,
# 				    41,27,11, 3,34,48,20,26,
# 				    52,36,15,47,60,31, 1,40,
# 				    54, 4,63,58,16,51,44,32,
# 				    55,24, 6,53,61, 8,35,45,
# 				    59,37,57,13,56,29,25, 0};
0380:	013
0381:	024
0382:	00f
0383:	02f
0384:	03c
0385:	01f
0386:	001
0387:	028
0388:	037
0389:	018
038a:	006
038b:	035
038c:	03d
038d:	008
038e:	023
038f:	02d
0390:	036
0391:	004
0392:	03f
0393:	03a
0394:	010
0395:	033
0396:	02c
0397:	020
0398:	01c
0399:	032
039a:	015
039b:	012
039c:	027
039d:	01e
039e:	021
039f:	017
03a0:	03b
03a1:	025
03a2:	039
03a3:	00d
03a4:	038
03a5:	01d
03a6:	019
03a7:	000
03a8:	034
03a9:	002
03aa:	02b
03ab:	00a
03ac:	007
03ad:	03e
03ae:	016
03af:	02e
03b0:	029
03b1:	01b
03b2:	00b
03b3:	003
03b4:	022
03b5:	030
03b6:	014
03b7:	01a
03b8:	011
03b9:	031
03ba:	009
03bb:	00c
03bc:	00e
03bd:	026
03be:	02a
03bf:	005

