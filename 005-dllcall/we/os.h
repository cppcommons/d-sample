#ifndef OS_H
#define OS_H

#ifdef __cplusplus
extern "C" {
#endif

struct os_variant_t;
typedef os_variant_t *os_value;
typedef os_value (*os_function_t)(long argc, os_value args[]);
typedef long long os_integer_t;
enum os_type_t
{
	OS_NIL,
	OS_ADDRESS,
	OS_ARRAY,
	OS_BYTES,
	OS_INTEGER,
	OS_OBJECT,
	OS_REAL,
	OS_STRING
};
extern int os_printf(const char *format, ...);
extern int os_dbg(const char *format, ...);
extern os_value os_new_integer(os_integer_t data);
extern os_integer_t os_get_integer(os_value value);
extern void os_set_integer(os_value value, os_integer_t data);
extern os_value os_new_string(const char *data, os_integer_t len);
extern void os_dump_object_heap();
extern void os_oid_link(os_value entry);
extern void os_oid_unlink(os_value entry);
extern void os_cleanup();

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus /* C++ only */
#include <string>
static inline os_value os_new_std_string(const std::string &data)
{
	return os_new_string(data.c_str(), data.size());
}
#endif /* __cplusplus (C++ only) */

#endif /* OS_H */