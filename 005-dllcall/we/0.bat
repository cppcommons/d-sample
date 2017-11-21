cl /MT 0.cpp /LD shell32.lib user32.lib
if %errorlevel% neq 0 ( exit /b )
::cmd32 0.dll a b c
run32 -nc 0.dll a b c
run32 0.dll a b c
run32 -ac 0.dll a b c
