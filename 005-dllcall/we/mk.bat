::emake-cpp build=release boost1.exe boost1.cpp -IE:\d-dev\boost_1_34_0 -LINK=-p512
::emake-cpp build=release boost1.exe boost1.cpp -IE:\d-dev\boost_1_50_headers -LINK=-p512
::emake-cpp build=release boost1.exe boost1.cpp -IE:\d-dev\boost_1_40_headers -LINK=-p512
::emake-cpp build=release boost1.exe boost1.cpp -IE:\d-dev\boost_1_34_1_headers -IC:\dm\stlsoft -LINK=-p512
emake-cpp build=release boost1.exe boost1.cpp -IE:\d-dev\boost_1_34_1_headers -IE:\d-dev\STLSoft-1.9.131\include -LINK=-p512
if %errorlevel% neq 0 ( exit /b )
chcp 65001
boost1.exe