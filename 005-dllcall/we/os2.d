/* Converted to D from os2.h by htod */
module os2;


class os_object
{
}

extern (C):
alias int os_int32;
alias uint os_uint32;
alias long os_int64;
alias ulong os_uint64;
alias os_uint64 os_size_t;
alias os_object  function(os_int32 argc, os_object *argv)os_function;
enum os_type
{
    OS_NIL,
    OS_ADDRESS,
    OS_BYTES,
    OS_OBJECT,
    OS_REAL,
    OS_STRING,
}
os_object  os_new_array(os_size_t size);
os_size_t  os_array_size(os_object array);
void  os_array_clear(os_object array);
os_object  os_get_value(os_object array_or_value, os_int64 index);
void  os_set_value(os_object array, os_int64 index, os_object data);
void  os_push_value(os_object array, os_object data);
os_object  os_new_address(void *data);
void * os_get_address(os_object array_or_value, os_int64 index);
void  os_set_address(os_object array, os_int64 index, void *data);
void  os_push_address(os_object array, void *data);
os_object  os_new_integer(os_int64 data);
os_int64  os_get_integer(os_object array_or_value, os_int64 index);
void  os_set_integer(os_object array, os_int64 index, os_int64 data);
void  os_push_integer(os_object array, os_int64 data);
os_object  os_new_string(char *data);
os_object  os_new_string2(char *data, os_size_t size);
char * os_get_string(os_object array_or_value, os_int64 index);
char * os_get_string2(os_object array_or_value, os_size_t *len, os_int64 index);
void  os_set_string(os_object array, os_int64 index, char *data);
void  os_push_string(os_object array, char *data);
void  os_set_string2(os_object array, os_int64 index, char *data, os_size_t size);
void  os_push_string2(os_object array, char *data, os_size_t size);
void  os_dump_heap();
bool  os_mark(os_object value);
bool  os_unmark(os_object value);
void  os_sweep();
void  os_clear();

os_int32  add(os_int32 i, os_int32 j);
os_int32  multiply(os_int32 i, os_int32 j);


