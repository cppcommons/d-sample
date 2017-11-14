#ifndef LIB1_H
#define LIB1_H

#ifdef __cplusplus
extern "C" {
#endif

#include "os1.h"

os_handle my_add2(os_heap heap, long argc, os_handle argv[]);
int d_mul2(int a, int b);

#ifdef __cplusplus
}
#endif

#endif /* LIB1_H */