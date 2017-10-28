setlocal

set SCRIPT=%~0
for /f "delims=\ tokens=*" %%z in ("%SCRIPT%") do (
  set SCRIPT_DRIVE=%%~dz
  set SCRIPT_PATH=%%~pz
  set SCRIPT_CURRENT_DIR=%%~dpz
)

cd /d %SCRIPT_CURRENT_DIR%
copy main.cmk CMakeLists.txt

set PATH=PATH=C:\Windows\system32;e:\opt\opt.m32\mingw32\qt5-static\bin;e:\opt\opt.m32\mingw32\bin;e:\opt\cmake-3.9.4-win64-x64\bin

set FOLDER=main-mg.bld

set REDO=0
if "%1" equ "redo" set REDO=1
if not exist %FOLDER% set REDO=1

if "%REDO%"=="1" (
  call easy.bat
  rmdir /s /q %FOLDER%
  mkdir %FOLDER%
  cd %FOLDER%
  cmake -G "MinGW Makefiles" -DCMAKE_C_COMPILER="gcc" -DCMAKE_CXX_COMPILER="g++" ..
  if %errorlevel% neq 0 ( exit /b )
)

cd /d %SCRIPT_CURRENT_DIR%
cd %FOLDER%

cmake --build . --config Release
if %errorlevel% neq 0 ( exit /b )

ctest -C Release -V
if %errorlevel% neq 0 ( exit /b )

endlocal
