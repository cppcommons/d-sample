#ifndef OS_H
#define OS_H

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __HTOD__
struct os_variant_t
{
};
#else
struct os_variant_t;
#endif
typedef os_variant_t *os_value;
typedef os_value (*os_function_t)(long argc, os_value argv[]);
//typedef long long os_integer_t;
enum os_type_t
{
	OS_NIL,
	OS_ADDRESS,
	OS_ARRAY,
	OS_BYTES,
	OS_INTEGER,
	//OS_OBJECT,
	OS_REAL,
	OS_STRING
};
extern int os_printf(const char *format, ...);
extern int os_dbg(const char *format, ...);
extern os_value os_new_integer(long long data);
extern long long os_get_integer(os_value value);
extern os_value os_new_string(const char *data, long long len);
extern const char *os_get_string(os_value value);
extern void os_dump_heap();
extern void os_link(os_value entry);
extern void os_unlink(os_value entry);
extern void os_cleanup();
extern long long os_arg_count(os_function_t fn);

#ifdef __cplusplus
}
#endif

#ifndef __HTOD__
#ifdef __cplusplus /* C++ only */
#include <string>
static inline os_value os_new_string(const std::string &data)
{
	return os_new_string(data.c_str(), data.size());
}
#endif /* __cplusplus (C++ only) */
#endif /* !__HTOD__ */

#endif /* OS_H */