// https://support.microsoft.com/en-us/help/164787/info-windows-rundll-and-rundll32-interface
#include <windows.h>
#include <stdio.h>

//extern "C" __declspec(dllexport)
//void CALLBACK EntryPointW(HWND hwnd, HINSTANCE hinst, LPWSTR lpszCmdLine, int nCmdShow)
extern "C" 
__declspec( dllexport )
void CALLBACK sayHello( HWND, HINSTANCE, wchar_t const*, int )
{
	::MessageBoxA(NULL, "aaa", "bbb", MB_OK);
    AllocConsole();
    freopen( "CONIN$", "r", stdin ); 
    freopen( "CONOUT$", "w", stdout ); 
    freopen( "CONOUT$", "w", stderr ); 

    DWORD const infoBoxOptions = MB_ICONINFORMATION | MB_SETFOREGROUND;
    MessageBoxW( 0, L"Before call...", L"DLL message:", infoBoxOptions );
    //myCode::sayHello();
    MessageBoxW( 0, L"After call...", L"DLL message:", infoBoxOptions );
	return;				   
}