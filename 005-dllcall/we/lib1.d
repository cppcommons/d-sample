/* Converted to D from lib1.h by htod */
module lib1;
//C     #ifndef LIB1_H
//C     #define LIB1_H

//C     #ifdef __cplusplus
//C     extern "C" {
//C     #endif

//C     #include "os1.h"
//import os1;
import b;

//os_handle my_add2(long argc, os_handle argv[]);
//C     extern os_object *my_add2(long argc, os_object *argv[]);
extern (C):
//os_object * my_add2(int argc, os_object **argv);
os_object my_add2(int argc, os_object *argv);
//C     int d_mul2(int a, int b);
int  d_mul2(int a, int b);

//C     #ifdef __cplusplus
//C     }
//C     #endif

//C     #endif /* LIB1_H */
