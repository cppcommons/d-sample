#ifndef OS_H
#define OS_H

#ifdef __cplusplus
extern "C" {
#endif

struct os_variant_t;
typedef os_variant_t *os_value;

typedef long long os_integer_t;

typedef os_value (*os_function_t)(long argc, os_value args[]);

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus /* C++ only */
#endif /* __cplusplus (C++ only) */

#endif /* OS_H */