setlocal

set SCRIPT=%~0
for /f "delims=\ tokens=*" %%z in ("%SCRIPT%") do (
  set SCRIPT_DRIVE=%%~dz
  set SCRIPT_PATH=%%~pz
  set SCRIPT_CURRENT_DIR=%%~dpz
)

copy main.cmk CMakeLists.txt
set FOLDER=main64.bld

cd /d %SCRIPT_CURRENT_DIR%

set REDO=0
if "%1" equ "redo" set REDO=1
if not exist %FOLDER% set REDO=1

if "%REDO%"=="1" (
  rmdir /s /q %FOLDER%
  mkdir %FOLDER%
  cd %FOLDER%
  cmake -G "Visual Studio 14 2015 Win64" -DCMAKE_CXX_FLAGS_RELEASE="/MT" -DCMAKE_CXX_FLAGS_DEBUG="/MTd" ^
                                         -DBOOST_LIBRARYDIR=E:\local\boost_1_61_0\lib32-msvc-14.0 ^
                                         ..
)

cd /d %SCRIPT_CURRENT_DIR%
cd %FOLDER%

cmake --build . --config Release

ctest -C Release -V

endlocal
