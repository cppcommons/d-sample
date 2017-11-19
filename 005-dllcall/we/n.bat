cl /MD n.cpp /LD shell32.lib user32.lib
if %errorlevel% neq 0 ( exit /b )
start rundll32 n.dll,_runServer@16 a b c
rundll32 n.dll,_runClient@16 a b c
