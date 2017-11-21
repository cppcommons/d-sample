emake-cpp build=release inet-app.exe inet.cpp wininet.lib ^
  -IE:\d-dev\boost_1_34_1_headers ^
  -IE:\d-dev\STLSoft-1.9.131\include -LINK=-p512
if %errorlevel% neq 0 ( exit /b )
inet-app.exe