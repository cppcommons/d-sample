#ifndef LIB1_H
#define LIB1_H

#ifdef __cplusplus
extern "C" {
#endif

#include "os1.h"

//typedef os_handle (*os_function)(long argc, os_handle argv[]);
os_handle my_add2(long argc, os_handle argv[]);
int d_mul2(int a, int b);

#ifdef __cplusplus
}
#endif

#endif /* LIB1_H */