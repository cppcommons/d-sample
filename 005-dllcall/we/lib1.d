/* Converted to D from lib1.h by htod */
module lib1;
//C     #ifndef LIB1_H
//C     #define LIB1_H

//C     #ifdef __cplusplus
//C     extern "C" {
//C     #endif

//C     #include "os1.h"
import os1;

//typedef os_handle (*os_function)(long argc, os_handle argv[]);
//C     os_handle my_add2(long argc, os_handle argv[]);
extern (C):
os_handle  my_add2(int argc, os_handle *argv);
//C     int d_mul2(int a, int b);
int  d_mul2(int a, int b);

//C     #ifdef __cplusplus
//C     }
//C     #endif

//C     #endif /* LIB1_H */
