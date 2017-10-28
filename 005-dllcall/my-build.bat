setlocal
del mylib.dll app1-dm32.exe
edub apps.json build :mylib --build=release
if %errorlevel% neq 0 ( exit /b )
edub apps.json run :app1 --build=release
if %errorlevel% neq 0 ( exit /b )
::edub apps.json build :app2 --build=release
::if %errorlevel% neq 0 ( exit /b )
endlocal
