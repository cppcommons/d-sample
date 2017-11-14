#ifndef OS1_H
#define OS1_H

#ifdef __cplusplus
extern "C" {
#endif

typedef const char *os_handle;
typedef unsigned long long os_size_t;
typedef os_handle (*os_function)(long argc, os_handle argv[]);
enum os_type
{
	OS_NIL,
	OS_ADDRESS,
	OS_ARRAY,
	OS_BYTES,
	OS_INTEGER,
	OS_REAL,
	OS_STRING
};
extern os_handle os_new_array(os_size_t size);
extern os_size_t os_array_size(os_handle array);
extern void os_array_clear(os_handle array);
extern os_handle os_get_value(os_handle array, os_size_t index = 0);
extern void os_set_value(os_handle array, os_size_t index, os_handle data);
extern void os_push_value(os_handle array, os_handle data);
extern os_handle os_new_address(void *data);
extern void *os_get_address(os_handle array_or_value, os_size_t index = 0);
extern void os_set_address(os_handle array, os_size_t index, void *data);
extern void os_push_address(os_handle array, void *data);
extern os_handle os_new_integer(long long data);
extern long long os_get_integer(os_handle array_or_value, os_size_t index = 0);
extern void os_set_integer(os_handle array, os_size_t index, long long data);
extern void os_push_integer(os_handle array, long long data);
extern os_handle os_new_string(const char *data);
extern os_handle os_new_string2(const char *data, os_size_t len);
extern const char *os_get_string(os_handle array_or_value, os_size_t index = 0);
extern const char *os_get_string2(os_handle array_or_value, os_size_t *len, os_size_t index = 0);
extern void os_set_string(os_handle array, os_size_t index, const char *data);
extern void os_push_string(os_handle array, const char *data);
extern void os_set_string2(os_handle array, os_size_t index, const char *data, os_size_t len);
extern void os_push_string2(os_handle array, const char *data, os_size_t len);
extern void os_dump_heap(os_size_t heap);
extern bool os_mark(os_handle value);
extern bool os_unmark(os_handle value);
extern void os_sweep(os_size_t heap);
extern void os_clear(os_size_t heap);

#ifdef __cplusplus
}
#endif

#endif /* OS1_H */