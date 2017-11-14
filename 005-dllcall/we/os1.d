/* Converted to D from os1.h by htod */
module os1;


extern (C):
alias ulong os_value;
alias os_value  function(int argc, os_value *argv)os_function;
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
long  os_get_length(os_value value);
os_value  os_new_array(long len);
os_value * os_get_array(os_value value);
os_value  os_new_handle(void *data);
void * os_get_handle(os_value value);
os_value  os_new_integer(long data);
long  os_get_integer(os_value value);
os_value  os_new_string(char *data, long len);
char * os_get_string(os_value value);
void  os_dump_heap();
bool  os_mark(os_value entry);
bool  os_unmark(os_value entry);
void  os_sweep();
void  os_clear();



