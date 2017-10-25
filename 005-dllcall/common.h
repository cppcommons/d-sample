//#ifdef ENABLE_TRACE
#if defined(_MSC_VER) || defined(__MINGW32__)
#include <windows.h>
#include <sstream>
#define trace(x) do { std::clog << x << std::endl; std::stringstream STRM; STRM << x << '\n'; OutputDebugStringA(STRM.str().c_str()); } while (0)
#else
#include <iostream>
#define trace(x) std::clog << x << std::endl
#endif // or std::cerr << x << std::flush
//#else
//#  define trace(x)
//#endif

#ifdef _MSC_VER
#define funcsig __FUNCSIG__
#else
#define funcsig __PRETTY_FUNCTION__
#endif
