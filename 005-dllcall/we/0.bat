cl /MD 0.cpp /LD shell32.lib user32.lib
if %errorlevel% neq 0 ( exit /b )
rundll32 0.dll,_run@16 a b c