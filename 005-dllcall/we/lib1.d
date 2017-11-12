/* Converted to D from lib1.h by htod */
module lib1;
//C     #ifndef LIB1_H
//C     #define LIB1_H

//C     #ifdef __cplusplus
//C     extern "C" {
//C     #endif

//C     #include "os.h"
import os;

//C     os_value my_add2(long argc, os_value argv[]);
extern (C):
os_value  my_add2(int argc, os_value *argv);

//C     #ifdef __cplusplus
//C     }
//C     #endif

//C     #endif /* LIB1_H */
