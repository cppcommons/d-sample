/* Converted to D from lib1.h by htod */
module lib1;
//C     #ifndef LIB1_H
//C     #define LIB1_H

//C     #ifdef __cplusplus
//C     extern "C" {
//C     #endif

//C     #include "os1.h"
import os1;

//C     os_value my_add2(os_heap heap, long argc, os_value argv[]);
extern (C):
os_value  my_add2(os_heap heap, int argc, os_value *argv);
//C     int d_mul2(int a, int b);
int  d_mul2(int a, int b);

//C     #ifdef __cplusplus
//C     }
//C     #endif

//C     #endif /* LIB1_H */
