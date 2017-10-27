setlocal

set SCRIPT=%~0
for /f "delims=\ tokens=*" %%z in ("%SCRIPT%") do (
  set SCRIPT_DRIVE=%%~dz
  set SCRIPT_PATH=%%~pz
  set SCRIPT_CURRENT_DIR=%%~dpz
)

cd /d %SCRIPT_CURRENT_DIR%
copy main.cmk CMakeLists.txt

set PATH=
set PATH=%PATH%;C:\Program Files\CMake\bin
set PATH=%PATH%;%SystemRoot%\System32

set BOOST_ROOT=E:\boost_1_65_1
set FOLDER=main.bld

set REDO=0
if "%1" equ "redo" set REDO=1
if not exist %FOLDER% set REDO=1

if "%REDO%"=="1" (
  rmdir /s /q %FOLDER%
  mkdir %FOLDER%
  cd %FOLDER%
  cmake -G "Visual Studio 14 2015" -DCMAKE_CXX_FLAGS_RELEASE="/MT" -DCMAKE_CXX_FLAGS_DEBUG="/MTd" ..
)

cd /d %SCRIPT_CURRENT_DIR%
cd %FOLDER%

cmake --build . --config Release

ctest -C Release -V

endlocal
