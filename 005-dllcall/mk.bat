del main-dm32.exe
C:\dm\bin\dmc -o main-dm32.exe -IC:/dm/stlport/stlport main.cpp lib_entry.lib
if %errorlevel% neq 0 ( exit /b )
