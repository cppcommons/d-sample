emake-cpp build=release os.lib os.cpp os.h -IE:\d-dev\boost_1_34_1_headers -IE:\d-dev\STLSoft-1.9.131\include -LINK=-p512
if %errorlevel% neq 0 ( exit /b )
emake-cpp build=release lib1.lib lib1.cpp -LINK=-p512
if %errorlevel% neq 0 ( exit /b )
emake-cpp build=release boost1.exe boost1.cpp os.lib lib1.lib ^
  -IE:\d-dev\boost_1_34_1_headers ^
  -IE:\d-dev\STLSoft-1.9.131\include -LINK=-p512
if %errorlevel% neq 0 ( exit /b )
boost1.exe
c:\dm\bin\htod -cpp os.h
c:\dm\bin\htod -cpp lib1.h
