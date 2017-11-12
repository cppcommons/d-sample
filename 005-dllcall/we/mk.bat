emake-cpp build=release os.lib os.cpp os.h -IE:\d-dev\boost_1_34_1_headers -IE:\d-dev\STLSoft-1.9.131\include -LINK=-p512
if %errorlevel% neq 0 ( exit /b )
emake-cpp build=release boost1.exe boost1.cpp os.lib -IE:\d-dev\boost_1_34_1_headers -IE:\d-dev\STLSoft-1.9.131\include -LINK=-p512
if %errorlevel% neq 0 ( exit /b )
chcp 65001
boost1.exe
c:\dm\bin\htod -cpp os.h
if %errorlevel% neq 0 ( exit /b )
