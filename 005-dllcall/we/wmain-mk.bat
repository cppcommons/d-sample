cl /MD wmain.cpp /link /out:wmain.exe /subsystem:windows user32.lib
if %errorlevel% neq 0 ( exit /b )
wmain.exe