#ifndef OS2_H
#define OS2_H

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__HTOD__)
class os_object
{
};
#else
struct os_object_t
{
};
typedef struct os_object_t *os_object;
#endif /* __HTOD__ */

#ifdef _MSC_VER
typedef __int32 os_int32;
typedef unsigned __int32 os_uint32;
typedef __int64 os_int64;
typedef unsigned __int64 os_uint64;
#else
typedef long os_int32;
typedef unsigned long os_uint32;
typedef long long os_int64;
typedef unsigned long long os_uint64;
#endif
typedef os_uint64 os_size_t;
typedef os_object (*os_function)(os_int32 argc, os_object argv[]);
enum os_type
{
	OS_NIL,
	OS_ADDRESS,
	OS_BYTES,
	OS_OBJECT,
	OS_REAL,
	OS_STRING
};
extern os_object os_new_array(os_size_t size);
extern os_size_t os_array_size(os_object array);
extern void os_array_clear(os_object array);
extern os_object os_get_value(os_object array_or_value, os_int64 index = -1);
extern void os_set_value(os_object array, os_int64 index, os_object data);
extern void os_push_value(os_object array, os_object data);
extern os_object os_new_address(void *data);
extern void *os_get_address(os_object array_or_value, os_int64 index = -1);
extern void os_set_address(os_object array, os_int64 index, void *data);
extern void os_push_address(os_object array, void *data);
extern os_object os_new_integer(os_int64 data);
extern os_int64 os_get_integer(os_object array_or_value, os_int64 index = -1);
extern void os_set_integer(os_object array, os_int64 index, os_int64 data);
extern void os_push_integer(os_object array, os_int64 data);
extern os_object os_new_string(const char *data);
extern os_object os_new_string2(const char *data, os_size_t size);
extern const char *os_get_string(os_object array_or_value, os_int64 index = -1);
extern const char *os_get_string2(os_object array_or_value, os_size_t *len, os_int64 index = -1);
extern void os_set_string(os_object array, os_int64 index, const char *data);
extern void os_push_string(os_object array, const char *data);
extern void os_set_string2(os_object array, os_int64 index, const char *data, os_size_t size);
extern void os_push_string2(os_object array, const char *data, os_size_t size);
extern void os_dump_heap();
extern bool os_mark(os_object value);
extern bool os_unmark(os_object value);
extern void os_sweep();
extern void os_clear();

extern os_int32 add(os_int32 i, os_int32 j);
extern os_int32 multiply(os_int32 i, os_int32 j);

#ifdef __cplusplus
}
#endif

#endif /* OS2_H */