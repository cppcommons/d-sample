/* Converted to D from os1.h by htod */
module os1;


//typedef unsigned long long os_value;
extern (C):
alias char *os_value;
alias ulong os_heap;
alias os_value  function(os_heap heap, int argc, os_value *argv)os_function;
enum os_type
{
    OS_NIL,
    OS_ARRAY,
    OS_BYTES,
    OS1_HANDLE,
    OS_INTEGER,
    OS_REAL,
    OS_STRING,
}
long  os_get_thread_index();
long  os_get_length(os_value value);
os_value  os_new_array(os_heap heap, long len);
os_value * os_get_array(os_value value);
os_value  os_new_handle(os_heap heap, void *data);
void * os_get_handle(os_value value);
os_value  os_new_integer(os_heap heap, long data);
long  os_get_integer(os_value value);
os_value  os_new_string(os_heap heap, char *data);
os_value  os_new_string2(os_heap heap, char *data, long len);
char * os_get_string(os_value value);
void  os_dump_heap(os_heap heap);
bool  os_mark(os_value value);
bool  os_unmark(os_value value);
void  os_sweep(os_heap heap);
void  os_clear(os_heap heap);


