setlocal

set SCRIPT=%~0
for /f "delims=\ tokens=*" %%z in ("%SCRIPT%") do (
  set SCRIPT_DRIVE=%%~dz
  set SCRIPT_PATH=%%~pz
  set SCRIPT_CURRENT_DIR=%%~dpz
)

set DLANGUI_VER=0.9.170

cd /d %SCRIPT_CURRENT_DIR%

rmdir /s /q dlangui-%DLANGUI_VER%
rmdir /s /q dlangui.src
dub fetch dlangui --cache=local --version=0.9.170
robocopy /E /NDL /NFL dlangui-%DLANGUI_VER%\dlangui .\dlangui.src
cd dlangui.src
dub build --build=release

cd /d %SCRIPT_CURRENT_DIR%

endlocal
