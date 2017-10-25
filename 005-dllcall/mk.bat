del main.exe
C:\dm\bin\dmc -IC:/dm/stlport/stlport main.cpp lib_entry.lib
if %errorlevel% neq 0 ( exit /b )
