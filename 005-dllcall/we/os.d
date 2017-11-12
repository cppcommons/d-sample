/* Converted to D from os.h by htod */
module os;
//C     #ifndef OS_H
//C     #define OS_H

//C     #ifdef __cplusplus
//C     extern "C" {
//C     #endif

//C     #ifdef __HTOD__
//C     typedef void *os_value;
extern (C):
alias void *os_value;
//C     #else
//C     typedef struct os_variant_t *os_value;
//C     #endif
//C     typedef os_value (*os_function_t)(long argc, os_value argv[]);
alias os_value  function(int argc, os_value *argv)os_function_t;
//C     enum os_type_t
//C     {
//C     	OS_NIL,
//C     	OS_ARRAY,
//C     	OS_BYTES,
//C     	OS_INTEGER,
//C     	OS_REAL,
//C     	OS_STRING
//C     };
enum os_type_t
{
    OS_NIL,
    OS_ARRAY,
    OS_BYTES,
    OS_INTEGER,
    OS_REAL,
    OS_STRING,
}
//C     #ifndef __HTOD__
//C     extern int os_printf(const char *format, ...);
//C     extern int os_dbg(const char *format, ...);
//C     #endif /* !__HTOD__ */
//C     extern os_value os_new_array(long long len);
os_value  os_new_array(long len);
//C     extern os_value *os_get_array(os_value value);
os_value * os_get_array(os_value value);
//C     extern os_value os_new_integer(long long data);
os_value  os_new_integer(long data);
//C     extern long long os_get_integer(os_value value);
long  os_get_integer(os_value value);
//C     extern os_value os_new_string(const char *data, long long len);
os_value  os_new_string(char *data, long len);
//C     extern const char *os_get_string(os_value value);
char * os_get_string(os_value value);
//C     extern void os_dump_heap();
void  os_dump_heap();
//C     extern bool os_mark(os_value entry);
bool  os_mark(os_value entry);
//C     extern bool os_unmark(os_value entry);
bool  os_unmark(os_value entry);
//C     extern void os_sweep();
void  os_sweep();
//C     extern void os_clear();
void  os_clear();
//C     extern long long os_arg_count(os_function_t fn);
long  os_arg_count(os_function_t fn);

//C     #ifdef __cplusplus
//C     }
//C     #endif

//C     #ifndef __HTOD__
//C     #ifdef __cplusplus /* C++ only */
//C     #include <string>
//C     static inline os_value os_new_string(const std::string &data)
//C     {
//C     	return os_new_string(data.c_str(), data.size());
//C     }
//C     #endif /* __cplusplus (C++ only) */
//C     #endif /* !__HTOD__ */

//C     #endif /* OS_H */
