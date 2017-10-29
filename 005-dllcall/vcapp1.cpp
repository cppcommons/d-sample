#include "vcapp1.h"
#include "hcommon.h"
#include <iostream>
#include <memory>
using namespace std;
int main(int argc, char const *argv[])
{
	trace("same");
	return 0;
}

__declspec(dllexport) int add2(int a, int b)
{
    return a + b;
}
