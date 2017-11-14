#ifndef OS1_H
#define OS1_H

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned long long os_value;
typedef unsigned long long os_heap;
typedef os_value (*os_function)(os_heap heap, long argc, os_value argv[]);
enum os_type
{
	OS_NIL,
	OS_ARRAY,
	OS_BYTES,
	OS1_HANDLE,
	OS_INTEGER,
	OS_REAL,
	OS_STRING
};
extern long long os_get_thread_index();
extern long long os_get_length(os_value value);
extern os_value os_new_array(os_heap heap, long long len);
extern os_value *os_get_array(os_value value);
extern os_value os_new_handle(os_heap heap, void *data);
extern void *os_get_handle(os_value value);
extern os_value os_new_integer(os_heap heap, long long data);
extern long long os_get_integer(os_value value);
extern os_value os_new_string(os_heap heap, const char *data, long long len);
extern const char *os_get_string(os_value value);
extern void os_dump_heap(os_heap heap);
extern bool os_mark(os_value value);
extern bool os_unmark(os_value value);
extern void os_sweep(os_heap heap);
extern void os_clear(os_heap heap);

struct os_int128
{
	unsigned long long high;
	unsigned long long low;
};

os_int128 test_func();

#ifdef __cplusplus
}
#endif

#endif /* OS1_H */