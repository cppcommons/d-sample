//#ifdef ENABLE_TRACE
#ifdef _MSC_VER
#include <windows.h>
#include <sstream>
#define trace(x) do { std::stringstream s; s << x << '\n'; OutputDebugStringA(s.str().c_str()); } while (0)
#else
#include <iostream>
#define trace(x) std::clog << (x)
#endif // or std::cerr << (x) << std::flush
//#else
//#  define trace(x)
//#endif

#ifdef _MSC_VER
#define funcsig __FUNCSIG__
#else
#define funcsig __PRETTY_FUNCTION__
#endif
