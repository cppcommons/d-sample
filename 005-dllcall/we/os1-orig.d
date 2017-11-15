/* Converted to D from os1.h by htod */
module os1-orig;


alias class OS_STRUCT;

class os_object
{
  private:
    char [256]eye_catcher;
}
class os_address;
class os_array;
class os_integer;
class os_string;
extern (C):
alias ulong os_size_t;
alias long os_offset_t;
alias os_object * function(int argc, os_object **argv)os_function;
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
os_array * os_new_array(os_size_t size);
os_size_t  os_array_size(os_object *array);
void  os_array_clear(os_object *array);
os_object * os_get_value(os_object *array_or_value, os_offset_t index);
void  os_set_value(os_object *array, os_offset_t index, os_object *data);
void  os_push_value(os_object *array, os_object *data);
os_address * os_new_address(void *data);
void * os_get_address(os_object *array_or_value, os_offset_t index);
void  os_set_address(os_object *array, os_offset_t index, void *data);
void  os_push_address(os_object *array, void *data);
os_integer * os_new_integer(long data);
long  os_get_integer(os_object *array_or_value, os_offset_t index);
void  os_set_integer(os_object *array, os_offset_t index, long data);
void  os_push_integer(os_object *array, long data);
os_string * os_new_string(char *data);
os_string * os_new_string2(char *data, os_size_t size);
char * os_get_string(os_object *array_or_value, os_offset_t index);
char * os_get_string2(os_object *array_or_value, os_size_t *len, os_offset_t index);
void  os_set_string(os_object *array, os_offset_t index, char *data);
void  os_push_string(os_object *array, char *data);
void  os_set_string2(os_object *array, os_offset_t index, char *data, os_size_t size);
void  os_push_string2(os_object *array, char *data, os_size_t size);
void  os_dump_heap();
bool  os_mark(os_object *value);
bool  os_unmark(os_object *value);
void  os_sweep();
void  os_clear();


