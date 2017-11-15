#ifndef OS1_H
#define OS1_H

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __HTOD__
#define OS_STRUCT class
#else
#define OS_STRUCT struct
#endif /* __HTOD__ */

OS_STRUCT os_object
{
	char eye_catcher[256];
};
OS_STRUCT os_address : public os_object
{
};
OS_STRUCT os_array : public os_object
{
};
OS_STRUCT os_integer : public os_object
{
};
OS_STRUCT os_string : public os_object
{
};
typedef unsigned long long os_size_t;
typedef long long os_offset_t;
typedef os_object *(*os_function)(long argc, os_object *argv[]);
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
extern os_array *os_new_array(os_size_t size);
extern os_size_t os_array_size(os_object *array);
extern void os_array_clear(os_object *array);
extern os_object *os_get_value(os_object *array_or_value, os_offset_t index = -1);
extern void os_set_value(os_object *array, os_offset_t index, os_object *data);
extern void os_push_value(os_object *array, os_object *data);
extern os_address *os_new_address(void *data);
extern void *os_get_address(os_object *array_or_value, os_offset_t index = -1);
extern void os_set_address(os_object *array, os_offset_t index, void *data);
extern void os_push_address(os_object *array, void *data);
extern os_integer *os_new_integer(long long data);
extern long long os_get_integer(os_object *array_or_value, os_offset_t index = -1);
extern void os_set_integer(os_object *array, os_offset_t index, long long data);
extern void os_push_integer(os_object *array, long long data);
extern os_string *os_new_string(const char *data);
extern os_string *os_new_string2(const char *data, os_size_t size);
extern const char *os_get_string(os_object *array_or_value, os_offset_t index = -1);
extern const char *os_get_string2(os_object *array_or_value, os_size_t *len, os_offset_t index = -1);
extern void os_set_string(os_object *array, os_offset_t index, const char *data);
extern void os_push_string(os_object *array, const char *data);
extern void os_set_string2(os_object *array, os_offset_t index, const char *data, os_size_t size);
extern void os_push_string2(os_object *array, const char *data, os_size_t size);
extern void os_dump_heap();
extern bool os_mark(os_object *value);
extern bool os_unmark(os_object *value);
extern void os_sweep();
extern void os_clear();

#ifdef __cplusplus
}
#endif

#endif /* OS1_H */