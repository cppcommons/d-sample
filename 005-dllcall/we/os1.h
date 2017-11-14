#ifndef OS1_H
#define OS1_H

#ifdef __cplusplus
extern "C" {
#endif

typedef const char *os_handle;
typedef unsigned long long os_heap;
typedef os_handle (*os_function)(os_heap heap, long argc, os_handle argv[]);
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
extern long long os_get_thread_index();
extern long long os_get_length(os_handle value);
extern os_handle os_new_array(os_heap heap, long long len);
extern os_handle *os_get_array(os_handle value);
extern os_handle os_new_address(os_heap heap, void *data);
extern void *os_get_address(os_handle value);
extern os_handle os_new_integer(os_heap heap, long long data);
extern long long os_get_integer(os_handle value);
extern os_handle os_new_string(os_heap heap, const char *data);
extern os_handle os_new_string2(os_heap heap, const char *data, long long len);
extern const char *os_get_string(os_handle value);
extern void os_dump_heap(os_heap heap);
extern bool os_mark(os_handle value);
extern bool os_unmark(os_handle value);
extern void os_sweep(os_heap heap);
extern void os_clear(os_heap heap);

#ifdef __cplusplus
}
#endif

#endif /* OS1_H */