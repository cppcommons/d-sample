setlocal
set SCRIPT=%~0
for /f "delims=\ tokens=*" %%z in ("%SCRIPT%") do (set SCRIPT_CURRENT_DIR=%%~dpz)
cd /d %SCRIPT_CURRENT_DIR%\huntlabs-orm-master
dub build --config=sqlite
copy entity.lib %SCRIPT_CURRENT_DIR%
cd /d %SCRIPT_CURRENT_DIR%
endlocal
::exit /b

chcp 65001

edub step2-ms64.exe run arch=ms64 ^
step2.d ^
[vibe-d] [dateparser] "[my-hibernated:@hibernated-0.3.2]"
::[vibe-d] [dateparser] "[hibernated::SQLite]"
if %errorlevel% neq 0 (exit /b)
exit /b

edub step2-ms64.exe run arch=ms64 ^
step2.d ^
[vibe-d] [dateparser] "[entity::sqlite]"
if %errorlevel% neq 0 (exit /b)
