c:\dm\bin\htod -cpp -hc os1.h os1-orig.d
::c:\dm\bin\htod -cpp lib1.h
::sed -i -e "s/import os1;/import b;/" lib1.d
emake-cpp build=release lib1.lib lib1.cpp -LINK=-p512
if %errorlevel% neq 0 ( exit /b )
