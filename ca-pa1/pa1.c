//---------------------------------------------------------------
//
//  4190.308 Computer Architecture (Fall 2021)
//
//  Project #1: Run-Length Encoding
//
//  September 14, 2021
//
//  Jaehoon Shim (mattjs@snu.ac.kr)
//  Ikjoon Son (ikjoon.son@snu.ac.kr)
//  Seongyeop Jeong (seongyeop.jeong@snu.ac.kr)
//  Systems Software & Architecture Laboratory
//  Dept. of Computer Science and Engineering
//  Seoul National University
//
//---------------------------------------------------------------



/* TODO: Implement this function */
int encode(const char* const src, const int srclen, char* const dst, const int dstlen)
{
    int s = 0, d = 0;
    char curByte = 0, cmpBit = 0, curBit = 0, curPos = 7, cnt = 0;//curPos: encoded 3bit의 msb의 byte에서의 위치

    while (s <= srclen){
        int i = 7;
        while (i > -1){
            if (s < srclen) curBit = (*(src + s) & (1 << i)) >> i;//curBit = 현재 바이트의 i번째 비트의 값
            
            if (cmpBit != curBit || cnt == 7 || s == srclen){//비교할 비트와 다를 때, 3bit이 모두 채워질 때, src의 마지막 바이트를 지났을 때.
                cmpBit = cmpBit ^ 1;
                if (curPos > 1) curByte = curByte | (cnt << (curPos - 2));
                else curByte = curByte | (cnt >> (2 - curPos));

                if (s == srclen && !curByte) break;
                curPos = (curPos + 5) % 8;
                *(dst + d) = curByte;
                
                if (curPos > 4){
                    curByte = 0;
                    curByte = cnt << (curPos + 1);
                    if (s == srclen && !curByte) break;
                    if (++d >= dstlen) return -1;
                    *(dst + d) = curByte;
                }
                cnt = 0;
            }
            else {
                cnt++;
                i--;
            }
        }
        s++;
    }
    if (!srclen) return 0;
    else return d + 1;
}

/* TODO: Implement this function */
int decode(const char* const src, const int srclen, char* const dst, const int dstlen)
{
    int s = 0, d = 0;
    char curByte = 0, countedBit = 0, curBit = 0, enPos = 2, curPos = 7; 
    /*
        curBit: 현재 src 바이트의 i번째 비트의 값이 무엇인지
        enPos: 현재 비트가 encoded 3bit에서는 몇 번째인지.
        curPos: dst에 넣을 바이트(curByte)에서 몇 번째 비트에 넣어야 할지
        countedBit: 카운트된 비트가 어떤 비트인지
    */

    while (s < srclen){
        int i = 7;
        while (i > -1){
            if (enPos < 0){
                enPos = 2;
                countedBit = countedBit ^ 1;
            }
            curBit = (*(src + s) & (1 << i)) >> i;
            for (int j = curBit << enPos; j; j--){
                curByte = curByte | (countedBit << curPos--);
                if (curPos < 0){
                    *(dst + d) = curByte;
                    curByte = 0;
                    curPos = 7;
                    if (++d >= dstlen) return -1;   
                }
            }
            i--;
            enPos--;
        }
        s++;
    }
    if (!srclen) return 0;
    else return d;
}
