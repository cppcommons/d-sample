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

edub step2.exe run arch=dm32 ^
step2.d qiitadb.lib ^
[vibe-d:data] [dateparser] "[my-hibernated#@hibernated-0.3.2]" "[d2sqlite3##without-lib]"
if %errorlevel% neq 0 (exit /b)
