/* Converted to D from os.h by htod */
module os;
//C     #ifndef OS_H
//C     #define OS_H

//C     #ifdef __cplusplus
//C     extern "C" {
//C     #endif

//C     #ifdef __HTOD__
//C     struct os_variant_t
//C     {
//C     };
struct os_variant_t
{
}
//C     #else
//C     struct os_variant_t;
//C     #endif
//C     typedef os_variant_t *os_value;
extern (C):
alias os_variant_t *os_value;
//C     typedef os_value (*os_function_t)(long argc, os_value argv[]);
alias os_value  function(int argc, os_value *argv)os_function_t;
//C     typedef long long os_integer_t;
alias long os_integer_t;
//C     enum os_type_t
//C     {
//C     	OS_NIL,
//C     	OS_ADDRESS,
//C     	OS_ARRAY,
//C     	OS_BYTES,
//C     	OS_INTEGER,
//C     	OS_OBJECT,
//C     	OS_REAL,
//C     	OS_STRING
//C     };
enum os_type_t
{
    OS_NIL,
    OS_ADDRESS,
    OS_ARRAY,
    OS_BYTES,
    OS_INTEGER,
    OS_OBJECT,
    OS_REAL,
    OS_STRING,
}
//C     extern int os_printf(const char *format, ...);
int  os_printf(char *format,...);
//C     extern int os_dbg(const char *format, ...);
int  os_dbg(char *format,...);
//C     extern os_value os_new_integer(os_integer_t data);
os_value  os_new_integer(os_integer_t data);
//C     extern os_integer_t os_get_integer(os_value value);
os_integer_t  os_get_integer(os_value value);
//C     extern os_value os_new_string(const char *data, os_integer_t len);
os_value  os_new_string(char *data, os_integer_t len);
//C     extern void os_dump_heap();
void  os_dump_heap();
//C     extern void os_link(os_value entry);
void  os_link(os_value entry);
//C     extern void os_unlink(os_value entry);
void  os_unlink(os_value entry);
//C     extern void os_cleanup();
void  os_cleanup();
//C     extern os_integer_t os_arg_count(os_function_t fn);
os_integer_t  os_arg_count(os_function_t fn);

//C     #ifdef __cplusplus
//C     }
//C     #endif

//#ifdef __cplusplus /* C++ only */
//#include <string>
//static inline os_value os_new_string(const std::string &data)
//{
//	return os_new_string(data.c_str(), data.size());
//}
//#endif /* __cplusplus (C++ only) */

//C     #endif /* OS_H */
