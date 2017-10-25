//#ifdef ENABLE_TRACE
#ifdef _MSC_VER
#include <windows.h>
#include <sstream>
#define trace(x)                             \
	do                                       \
	{                                        \
		std::stringstream s;                 \
		s << x << '\n';                      \
		OutputDebugStringA(s.str().c_str()); \
	} while (0)
#else
#include <iostream>
#define trace(x) std::clog << (x)
#endif // or std::cerr << (x) << std::flush
//#else
//#  define trace(x)
//#endif

//#include "stdafx.h"
#include <stdio.h>

int main()
{
	int v1 = 123;
	double v2 = 456.789;
	trace("main() v1=" << v1 << " v2=" << v2);
	trace("main() v1=" << v1 << " v2=" << v2);
	return 0;
}
