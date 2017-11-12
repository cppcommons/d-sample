#ifndef OS_H
#define OS_H

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __HTOD__
typedef void *os_value;
#else
typedef struct os_variant_t *os_value;
#endif
typedef os_value (*os_function_t)(long argc, os_value argv[]);
enum os_type_t
{
	OS_NIL,
	OS_ARRAY,
	OS_BYTES,
	OS_HANDLE,
	OS_INTEGER,
	OS_REAL,
	OS_STRING
};
#ifndef __HTOD__
extern int os_printf(const char *format, ...);
extern int os_dbg(const char *format, ...);
#endif /* !__HTOD__ */
extern os_value os_new_array(long long len);
extern os_value *os_get_array(os_value value);
extern os_value os_new_handle(void *data);
extern void *os_get_handle(os_value value);
extern os_value os_new_integer(long long data);
extern long long os_get_integer(os_value value);
extern os_value os_new_string(const char *data, long long len);
extern const char *os_get_string(os_value value);
extern void os_dump_heap();
extern bool os_mark(os_value entry);
extern bool os_unmark(os_value entry);
extern void os_sweep();
extern void os_clear();
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