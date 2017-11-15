/* Converted to D from os1.h by htod */
module os1;


extern (C):
alias char *os_handle;
alias ulong os_size_t;
alias long os_offset_t;
alias os_handle  function(int argc, os_handle *argv)os_function;
enum os_type
{
    OS_NIL,
    OS_ADDRESS,
    OS_ARRAY,
    OS_BYTES,
    OS_INTEGER,
    OS_REAL,
    OS_STRING,
}
os_handle  os_new_array(os_size_t size);
os_size_t  os_array_size(os_handle array);
void  os_array_clear(os_handle array);
os_handle  os_get_value(os_handle array_or_value, os_offset_t index);
void  os_set_value(os_handle array, os_offset_t index, os_handle data);
void  os_push_value(os_handle array, os_handle data);
os_handle  os_new_address(void *data);
void * os_get_address(os_handle array_or_value, os_offset_t index);
void  os_set_address(os_handle array, os_offset_t index, void *data);
void  os_push_address(os_handle array, void *data);
os_handle  os_new_integer(long data);
long  os_get_integer(os_handle array_or_value, os_offset_t index);
void  os_set_integer(os_handle array, os_offset_t index, long data);
void  os_push_integer(os_handle array, long data);
os_handle  os_new_string(char *data);
os_handle  os_new_string2(char *data, os_size_t size);
char * os_get_string(os_handle array_or_value, os_offset_t index);
char * os_get_string2(os_handle array_or_value, os_size_t *len, os_offset_t index);
void  os_set_string(os_handle array, os_offset_t index, char *data);
void  os_push_string(os_handle array, char *data);
void  os_set_string2(os_handle array, os_offset_t index, char *data, os_size_t size);
void  os_push_string2(os_handle array, char *data, os_size_t size);
void  os_dump_heap();
bool  os_mark(os_handle value);
bool  os_unmark(os_handle value);
void  os_sweep();
void  os_clear();


