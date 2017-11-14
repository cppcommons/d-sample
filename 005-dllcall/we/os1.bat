c:\dm\bin\htod -cpp -hc os1.h
c:\dm\bin\htod -cpp lib1.h
emake-cpp build=release lib1.lib lib1.cpp -LINK=-p512
if %errorlevel% neq 0 ( exit /b )
