0000:	JA20
0001:	000c		;;; uint16_t a=11;
0002:	000b		;;; uint16_t b=12;
0003:	0000		;;; uint16_t bit_0_von_a = 0;
0014:	0000		;;; uint16_t sum = 0
0015:	0008		;;; uint16_t i = 8

0006:	0001			; const uint16_t k1=1
;;;

;;; do {
;;;     bit_0_von_a = a & 0x01;
0020:	LDM01
0021:	AND06
0022:	STM03
;;;     if (bit_0_von_a == 1) {
0023:	JZA40
;;;         sum = sum + b;
0024:	LDM14
0025:	ADD02
0026:	STM14
0027:	JA40
;;;     }
;;;     a = a >> 1;
0040:	LDM01
0041:	RIGT01
0042:	STM01
;;;     b = b << 1;
0043:	LDM02
0044:	LEFT01
0045:	STM02
;;;     i = i - 1;
0046:	LDM15
0047:	SUB06
0048:	STM15
;;; } while (i > 0)
0049:	JZA60
004a:	JA20

0060:	JA60 			; ENde
