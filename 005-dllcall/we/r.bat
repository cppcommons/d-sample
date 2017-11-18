::cl /MD rdll.cpp rdll.def /LD /link kernel32.lib user32.lib
cl /MD rdll.cpp /LD /link kernel32.lib user32.lib
if %errorlevel% neq 0 ( exit /b )
::rundll32 rdll.dll,sayHello
rundll32 rdll.dll,_sayHello@16
