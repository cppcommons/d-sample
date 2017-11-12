emake-cpp build=release boost1.exe boost1.cpp -IE:\d-dev\boost_1_34_1_headers -IE:\d-dev\STLSoft-1.9.131\include -LINK=-p512
if %errorlevel% neq 0 ( exit /b )
chcp 65001
boost1.exe
emake-cpp build=release boost1.lib boost1.cpp -IE:\d-dev\boost_1_34_1_headers -IE:\d-dev\STLSoft-1.9.131\include -LINK=-p512
if %errorlevel% neq 0 ( exit /b )
