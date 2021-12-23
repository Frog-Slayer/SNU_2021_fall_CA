//---------------------------------------------------------------
//
//  4190.308 Computer Architecture (Fall 2021)
//
//  Project #2: FP10 (10-bit floating point) Representation
//
//  October 5, 2021
//
//  Jaehoon Shim (mattjs@snu.ac.kr)
//  Ikjoon Son (ikjoon.son@snu.ac.kr)
//  Seongyeop Jeong (seongyeop.jeong@snu.ac.kr)
//  Systems Software & Architecture Laboratory
//  Dept. of Computer Science and Engineering
//  Seoul National University
//
//---------------------------------------------------------------

#include "pa2.h"
#define fSign ((int)((*(unsigned*)&f) & 0X80000000) >> 22)

/* Convert 32-bit signed integer to 10-bit floating point */
fp10 int_fp10(int n)
{
	/*0 is always +0*/
	if (!n) return 0;

	/*if n exceeds ~*/
	if (n > 0XFC00) return 0X1F0;
	if (n < -0XFC00) return 0XFFF0;

	/*dup sign bit*/
	int abs = n < 0? -n : n;
	fp10 ret = n < 0? 0XFE00 : 0;

	/*find ms1 in exp*/
	char i = 15;
	while (!(abs & (1 << i))) i--;

	/* round to even*/
	if ((i > 4) && (abs & (1 << (i-5)))) {
		abs += (((i > 5) && (abs & ((1 << (i - 5)) - 1))) || (abs & (1 << (i - 4)))) << (i - 4);
		i = 15;
		while (!(abs & (1 << i))) i--;
	}

	ret |= ((i + 15) << 4) | ((i - 3) ? ((abs & ~(1 << i)) >> (i - 4)) : ((abs & ~(1 << i)) << (4 - i)));
	return ret;
}

/* Convert 10-bit floating point to 32-bit signed integer */
int fp10_int(fp10 x)
{
	/*if x has denormalized value return 0*/
	if ((x | 0XFE0F) == 0XFE0f) return 0;

	/*if x is NAN or INF return the minimum number in int*/
	if ((x & 0X1F0) ==  0X1F0) return 0X80000000;

	int ret;
	if (((x & 0X1F0) >> 4) > 19) ret = (0X10 | (x & 0XF)) <<  (((x & 0X1F0) >> 4) - 19);
	else ret =  (0x10 | (x & 0XF)) >> (19 - ((x & 0X1F0) >> 4));

	return (x & (1 << 15)) ? -ret : ret;
}

/* Convert 32-bit single-precision floating point to 10-bit floating point */
fp10 float_fp10(float f)
{
	//Single precision : 1'b sign, 8'b exp, 23'b frac
	register unsigned fl = ((*(unsigned*)&f) << 1) >> 1;
	if (fl > 0x477c0000) {
		if (fl < 0x7f800001) return fSign | 0X1F0;//too big or inf => inf
		return fSign | 0X1F1;//nan
	}
	if (fl < 0x367FFFFF) return fSign;//too small => 0		
	if (fl < 0X38FFFFFF) fl = 0x38000000 | ((0x800000 | (fl & 0x7fffff)) >> (113 -(fl >> 23)));
	if ((fl & 0xfffff) > 0x40000)  fl += 0x40000; //round-to-even
	return fSign | ((fl >> 19) -0X700);
}
/* Convert 10-bit floating point to 32-bit single-precision floating point */
float fp10_float(fp10 x)
{
	/*Define union to use bitwise operators*/
	union ret {
		int i;
		float f;
	} ret;
	ret.i = 0;

	/* +-NAN => +-NAN, +-INF => +-INF*/
	if ((x & 0X1F0) == 0X1F0){
		if ((x | 0XFFF0) == 0XFFF0) ret.i = (x & (1<< 15)) ? 0XFF800000 : 0X7F800000;
		else ret.i = (x & (1 << 15)) ? 0XFF800001 : 0X7F800001;
	}
	else if ((x | 0XFE0F) == 0XFE0F){  /*denormalized*/
		int i = 3;
		while ((i > -1) && !(x & (1 << i))) i--;
		ret.i |= ((x & (1 << 15)) ? 1 << 31 : 0);
		if (i != -1) ret.i |= ((109 + i) << 23) | ((x & ~(0XFFF0 | (1 << i))) << (23 -i));
	}
	else ret.i |= ((x & (1<< 15) ? 1 << 31 : 0) | ((((x & 0X1F0)  >> 4) + 112) << 23) | ((x & 0XF) << 19)); /*Normalized*/
	return ret.f;
}
