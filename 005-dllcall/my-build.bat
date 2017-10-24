setlocal
del mylib.dll app1-dm32.exe
dub build :mylib --build=release
if %errorlevel% neq 0 ( exit /b )
dub run :app1 --build=release
if %errorlevel% neq 0 ( exit /b )
::dub build :app2 --build=release
::if %errorlevel% neq 0 ( exit /b )
endlocal
