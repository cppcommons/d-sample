setlocal
call "C:\Program Files (x86)\Microsoft Visual Studio\VC98\Bin\VCVARS32.BAT"
@echo on
::cl /MD rdll.cpp rdll.def /LD /link kernel32.lib user32.lib
cl /MD rdll.cpp /LD /link kernel32.lib user32.lib
if %errorlevel% neq 0 ( exit /b )
endlocal
::rundll32 rdll.dll,sayHello
rundll32 rdll.dll,_sayHello@16
